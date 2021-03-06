namespace :ceew_districts do
    task load: :environment do
        ceew_account = Rails.env.development? ? Account.friendly.find('pykih') : Account.friendly.find('ceew')
        ceew_site = ceew_account.site
        current_user = User.find(2)
        template_page = TemplatePage.where(name: 'article').first
        district_folder = Rails.env.development? ? Folder.friendly.find('test') : Folder.find(502) # Pages Folder
        district_policy_folder = Rails.env.development? ? Folder.friendly.find('test') : Folder.find(503) # DA and Policy
        # Create all the pages
        all_districts = JSON.parse(File.read("#{Rails.root.to_s}/ref/ceew/districts_profile.json"))
        t_profile_card = TemplateCard.where(name: "toProfile").first
        heroflow2_card_id = Rails.env.production? ? 7751  : 4485

        all_districts.each do |d|
            puts d
            puts "----------"
            district = d["District"]
            state = d["State"]
            headline = "#{district}, #{state}"
            puts headline
            puts "==========="
            page = Page.where(headline: headline).first
            if page.blank?
                page = Page.create({
                    site_id: ceew_site.id,
                    account_id: ceew_account.id,
                    headline: headline,
                    created_by: current_user.id,
                    updated_by: current_user.id,
                    folder_id: district_folder.id,
                    template_page_id: template_page.id,
                    byline_id: current_user.id,
                    english_headline: headline,
                    ref_category_series_id: district_folder.ref_category_vertical_id,
                    published_at: Time.now,
                    meta_keywords: "", meta_description: "", summary: ""
                })
            end

            hero_stream = page.streams.where(title: "#{page.id}_Story_16c_Hero").first

            narrative_stream = page.streams.where(title: "#{page.id}_Story_Narrative").first

            related_stream = page.streams.where(title: "#{page.id}_Story_Related").first

            StreamEntity.create({
                stream_id: hero_stream.id,
                entity_type: "view_cast_id",
                entity_value: "#{heroflow2_card_id}",
                created_by: current_user.id,
                updated_by: current_user.id,
                sort_order: 1
            })

            # Creating profile cards
            puts "creating profile card"

            datacast_params = {"data": {
                "title": headline,
                "description": " ",
                "image_url": d["image_url"],
                "details": [
                  {
                    "key": "Number of operational holdings",
                    "value": "#{d["Number of operational holdings"]}"
                  },
                  {
                    "key": "Average size of operational holding (Ha)",
                    "value": "#{d["Average size of operational holding (Ha)"]}"
                  },
                  {
                    "key": "No. of cultivators using diesel pumps",
                    "value": "#{d["No. of cultivators using diesel pumps"]}"
                  },
                  {
                    "key": "No. of cultivators using electric pumps",
                    "value": "#{d["No. of cultivators using electric pumps"]}"
                  }
                ],
                "section": headline
            }}

            payload = {}
            payload["payload"] = datacast_params.to_json
            payload["source"]  = "form"
            profile_card = ViewCast.create({
                site_id: ceew_site.id,
                account_id: ceew_account.id,
                name: headline,
                seo_blockquote: "",
                folder_id: district_folder.id,
                ref_category_vertical_id: district_folder.ref_category_vertical_id,
                template_card_id: t_profile_card.id,
                template_datum_id:  t_profile_card.template_datum_id,
                created_by: current_user.id,
                updated_by: current_user.id
            })
            payload["api_slug"] = profile_card.datacast_identifier
            payload["schema_url"] = profile_card.template_datum.schema_json
            payload["bucket_name"] = ceew_site.cdn_bucket

            r = Api::ProtoGraph::Datacast.create(payload)
            if r.has_key?("errorMessage")
                profile_card.destroy
                puts r['errorMessage']
                puts "================="
            else
                puts "Saved Profile Card"
            end

            StreamEntity.create({
                stream_id: related_stream.id,
                entity_type: "view_cast_id",
                entity_value: "#{profile_card.id}",
                created_by: current_user.id,
                updated_by: current_user.id,
                sort_order: 1
            })

            hero_stream.publish_cards
            narrative_stream.publish_cards

            # Publish the page
            page.status = "published"
            page.save
            puts "publishing page"
            puts "---------------------------"
            page.push_page_object_to_s3
        end
    end

    task create_data_pages: :environment do
        policies = [
            "Deployment Approach 1 - Private Ownership of pump",
            "Deployment Approach 2 - Solarization of feeders",
            "Deployment Approach 3 - Water-as-a-service",
            "Deployment Approach 4 - Promote 1 HP and sub-HP pump",
            "Har Khet ko Pani",
            "Per Drop More Crop",
            "Doubling cultivator's Income - capital investment",
            "Doubling cultivator's Income - crop intensity",
            "Doubling cultivator's Income - crop diversification",
            "National Mission on Oilseeds and Oil Palm (NMOOP)",
            "Sub-Mission on Agricultural Mechanisation - Farm Power Availability",
            "Climate Resilient Farming for Small Farms"
        ]

        account = Rails.env.development? ? Account.friendly.find('pykih') : Account.friendly.find('ceew')
        site = account.site
        folder =  Rails.env.development? ? site.folders.where.not(ref_category_vertical_id: nil).first : site.folders.where(slug: "da-and-policies").first
        template_page_id = TemplatePage.find_by(name: "Ceew: data grid").id

        policies.each do |p|
            begin
                page = Page.find_by(headline: p)
                unless page.present?
                    page = Page.create({
                        site_id: site.id,
                        account_id: account.id,
                        headline: p,
                        created_by: 2,
                        updated_by: 2,
                        folder_id: folder.id,
                        template_page_id: template_page_id,
                        byline_id: 2,
                        english_headline: p,
                        ref_category_series_id: folder.ref_category_vertical_id
                    })
                end

                page.status = "published"
                page.save

                page.push_page_object_to_s3
            rescue => e
                puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                puts "ERROR #{e}"
                puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            end

            sleep 2.seconds
        end
    end

    task load_summary: :environment do
        puts "Adding Summary to all pages"
        all_districts = JSON.parse(File.read("#{Rails.root.to_s}/ref/ceew/summary.json"))

        all_districts.each do |d|
            headline = "#{d["district"]}, #{d["state"]}"
            page = Page.where(headline: headline).first

            if page.present?
                puts "#{headline}"
                puts "#{page.html_url}"
                puts "============="
                page.content = d["summary"]
                page.prepare_cards_for_assembling= 'true'
                page.save
                page.push_page_object_to_s3
            end
        end
    end

    task load_parameters: :environment do
        puts "Adding All parameters"
        ceew_account = Rails.env.development? ? Account.friendly.find('pykih') : Account.friendly.find('ceew')
        ceew_site = ceew_account.site
        current_user = User.find(2)
        # all_districts = JSON.parse(File.read("#{Rails.root.to_s}/ref/ceew/parameters.json"))
        district_parameters_folder = Rails.env.development? ? Folder.friendly.find('test') : Folder.friendly.find('district-about-and-parameters') # Summary, About and Parameters
        t_parameter_card = TemplateCard.where(name: 'Ceew: Parameter').first
        parameters_map = {
            "Unirrigated net sown area ('000 ha)" => ["unirr_value", "unirr_percentile"],
            "Area under horticulture crops as a share of gross cropped area" => ["horti_value", "horti_percentile"],
            "Water Availability Index" => ["water_value", "water_percentile_1"],
            "Monthly per capita expenditure of rural agricultural households (INR)" => ["mpce_value", "mpce_percentile"],
            "Crop revenue per holding (INR)" => ["rev_value", "rev_percentile"],
            "No. of rural and semi-urban bank branches per 10,000 farmers" => ["bank_value", "bank_percentile"],
            "Medium and long-term institutional credit disbursed in a year (in INR Crore)" => ["credit_value", "credit_percentile"],
            "No. of calls made at Kisan Call Centre (between 1.1.2011 - 31.12.2015)" => ["kcc_value", "kcc_percentile"],
            "Level of farm mechanisation (tractors, harvesters, threshers per ha)" => ["fmech_value", "fmech_percentile"]
        }
        all_districts.each do |d|
            headline = "#{d["district".to_sym]}, #{d["state".to_sym]}"
            page = Page.where(headline: headline).first
            if page.present?
                puts "#{headline}"
                puts "#{page.html_url}"
                puts "============="
                related_stream = page.streams.where(title: "#{page.id}_Story_Related").first
                start_sort_order = 2
                parameters_map.each do |param, value|
                    puts param
                    puts "==========="
                    datacast_params = { "data": {
                            "title": param,
                            "display": "#{d[value[0].to_sym]}",
                            "percentile": "#{d[value[1].to_sym]}",
                            "district": d["district".to_sym]
                        }
                    }

                    payload = {}
                    payload["payload"] = datacast_params.to_json
                    payload["source"]  = "form"
                    profile_card = ViewCast.create({
                        site_id: ceew_site.id,
                        account_id: ceew_account.id,
                        name: "#{headline} - #{param}",
                        seo_blockquote: "",
                        folder_id: district_parameters_folder.id,
                        ref_category_vertical_id: district_parameters_folder.ref_category_vertical_id,
                        template_card_id: t_parameter_card.id,
                        template_datum_id:  t_parameter_card.template_datum_id,
                        created_by: current_user.id,
                        updated_by: current_user.id
                    })
                    payload["api_slug"] = profile_card.datacast_identifier
                    payload["schema_url"] = profile_card.template_datum.schema_json
                    payload["bucket_name"] = ceew_site.cdn_bucket

                    r = Api::ProtoGraph::Datacast.create(payload)
                    if r.has_key?("errorMessage")
                        profile_card.destroy
                        puts r['errorMessage']
                        puts "================="
                    else
                        puts "Saved Profile Card"
                    end

                    StreamEntity.create({
                        stream_id: related_stream.id,
                        entity_type: "view_cast_id",
                        entity_value: "#{profile_card.id}",
                        created_by: current_user.id,
                        updated_by: current_user.id,
                        sort_order: start_sort_order
                    })

                    start_sort_order += 1
                end
                related_stream.publish_cards
                response = Api::ProtoGraph::Page.create_or_update_page(page.datacast_identifier, page.template_page.s3_identifier, ceew_site.cdn_bucket, ENV['AWS_S3_ENDPOINT'])
                # page.push_page_object_to_s3
            end
        end
    end


    #Add that extra filter before you start.
    task load_da_and_policies: :environment do
        puts "Adding DA and Policies to all pages"
        ceew_account = Rails.env.development? ? Account.friendly.find('pykih') : Account.friendly.find('ceew')
        ceew_site = ceew_account.site
        current_user = User.find(2)
        all_districts = JSON.parse(File.read("#{Rails.root.to_s}/ref/ceew/da_and_policy.json"))
        drilldown_template_card = TemplateCard.where(name: "Ceew: PolicyDrillDown").first
        district_policy_folder = Rails.env.development? ? Folder.friendly.find('test') : Folder.find(503) # DA and Policy

        da_map = {
            "Individually owned off-grid solar pumps" => {
                "No. of cultivators reporting use of diesel pumps" => [
                    "cultivators_reporting_use_of_diesel_pumps_value",
                    "cultivators_reporting_use_of_diesel_pumps_percentile"
                ],
                "Water Availability Index" => [
                    "scarcity_index_score_value",
                    "scarcity_index_score_percentile"
                ],
                "Crop revenue per holding (INR)" => ["crop_revenue_value", "crop_revenue_percentile"],
                "Medium and long-term institutional credit disbursed in a year (in INR Crore)": [
                    "institutional_credit_disbursed_value",
                    "institutional_credit_disbursed_percentile"
                ]
            },
            "Solarisation of feeders" => {
                "Power purchase rate for DISCOM (INR/kWh)" => [
                    "power_purchase_rate_value",
                    "power_purchase_rate_percentile"
                ],
                "Extent of feeder segregation" => [
                    "feeder_segregation_extent_value",
                    "feeder_segregation_extent_percentile"
                ],
                "Proportion of cultivators reporting use of electric pumps" => [
                    "electric_pumps_proportion_value",
                    "electric_pumps_proportion_percentile"
                ]
            },
            "Solar based water as a service" => {
                "Water Availability Index" => [
                    "scarcity_index_score_value",
                    "scarcity_index_score_percentile"
                ],
                "Proportion of small and marginal cultivators" => [
                    "cultivators_proportion_value",
                    "cultivators_proportion_percentile"
                ],
                "Unirrigated net sown area as a share of total net sown area" => [
                    "unirrigated_net_sown_area_as_share_value",
                    "unirrigated_net_sown_area_as_share_percentile"
                ]
            },
            "Promote 1 HP and sub-HP pumps" => {
                "Area under horticulture crops as a share of gross cropped area" => [
                    "area_under_horticulture_crops_value",
                    "area_under_horticulture_crops_percentile"
                ],
                "Water Availability Index" => [
                    "scarcity_index_score_value",
                    "scarcity_index_score_percentile"
                ],
                "Proportion of marginal cultivators" => [
                    "marginal_cultivators_proportion_value",
                    "marginal_cultivators_proportion_percentile"
                ],
                "Medium and long-term institutional credit disbursed in a year to small and marginal cultivators (in INR Crore)" => [
                    "institutional_credit_disbursed_to_marginal_value",
                    "institutional_credit_disbursed_to_marginal_percentile"
                ]
            }
        }

        policy_map = {
            "Har Khet ko Pani" => {
                "Unirrigated net sown area as a share of total net sown area" => [
                    "unirrigated_net_sown_area_as_share_value",
                    "unirrigated_net_sown_area_as_share_percentile"
                ]
            },
            "Per Drop More Crop" => {
                "Area under crops suitable for drip and sprinkler irrigation as a share of total cropped area" => [
                    "area_for_drip_irrigation_value",
                    "area_for_drip_irrigation_percentile"
                ]
            },
            "Doubling Farmers' Income - Capital Investment" => {
                "Proportion of small and marginal cultivators" => [
                    "cultivators_proportion_value",
                    "cultivators_proportion_percentile"
                ],
                "Medium and long-term institutional credit disbursed in a year to small and marginal cultivators (in INR Crore)" => [
                    "institutional_credit_disbursed_to_small_and_marginal_value",
                    "institutional_credit_disbursed_to_small_and_marginal_percentile"
                ]
            },
            "Doubling Farmers' Income - Crop Intensity" => {
                "Unirrigated net sown area as a share of total net sown area" => [
                    "unirrigated_net_sown_area_as_share_value",
                    "unirrigated_net_sown_area_as_share_percentile"
                ]
            },
            "Doubling Farmers' Income - Crop Diversification" => {
                "Area under horticulture crops as a share of gross cropped area" => [
                    "area_under_horticulture_crops_value",
                    "area_under_horticulture_crops_percentile"
                ]
            },
            "National Mission on Oilseeds and Oil Palm (NMOOP)" => {
                "Area under oilseeds as a share of total cropped area" => [
                    "oilseeds_crops_area_display",
                    "oilseeds_crops_area_score"
                ]
            },
            "Sub-Mission on Agricultural Mechanisation - Farm Power Availability" => {
                "Level of farm mechanisation (tractors, harvesters, threshers per ha)" => [
                    "farm_mechanisation_level_value",
                    "farm_mechanisation_level_percentile"
                ],
                "Proportion of cultivators reporting use of electric pumps" => [
                    "electric_pumps_proportion_value",
                    "electric_pumps_proportion_percentile"
                ]
            },
            "Climate Resilient Farming for Small Farms" => {
                "Proportion of small and marginal cultivators" => [
                    "cultivators_proportion_value",
                    "cultivators_proportion_percentile"
                ],
                "Score on Climate Change Vulnerability Index" => [
                    "climate_resilient_score_value",
                    "climate_resilient_score_percentile"
                ]
            }
        }

        all_districts.each do |d|
            headline = "#{d["district"]}, #{d["state"]}"
            page = Page.where(headline: headline).first
            if page.present?
                puts "#{headline}"
                puts "#{page.html_url}"
                puts "============="
                da_para_id = Rails.env.development? ? 4572 : 15803
                policy_para_id = Rails.env.development? ? 4573 : 15804

                narrative_stream = page.streams.where(title: "#{page.id}_Story_Narrative").first

                start_sort_order = 2
                StreamEntity.create({
                    stream_id: narrative_stream.id,
                    entity_type: "view_cast_id",
                    entity_value: "#{da_para_id}",
                    created_by: current_user.id,
                    updated_by: current_user.id,
                    sort_order: start_sort_order
                })

                da_map.each do |da, mapping|
                    puts "++++++++++++++"
                    start_sort_order += 1
                    #Create Drilldowncard
                    is_recommended_text = d["Suitability - #{da}"]
                    title = "#{headline} - #{da}"
                    datacast_params = {data: {
                        "title": "#{da}",
                        "verdict": "#{is_recommended_text}",
                        "description": d[da],
                        "district": d["district"],
                        "parameters": []
                    }}

                    mapping.each do |parameter, v|
                        obj = {}
                        obj["title"] = parameter
                        obj["display"] = "#{d[v[0]]}"
                        obj["percentile"] = "#{d[v[1]]}"
                        datacast_params[:data][:parameters] << obj
                    end

                    payload = {}
                    payload["payload"] = datacast_params.to_json
                    payload["source"]  = "form"
                    profile_card = ViewCast.create({
                        site_id: ceew_site.id,
                        account_id: ceew_account.id,
                        name: title,
                        seo_blockquote: "",
                        folder_id: district_policy_folder.id,
                        ref_category_vertical_id: district_policy_folder.ref_category_vertical_id,
                        template_card_id: drilldown_template_card.id,
                        template_datum_id:  drilldown_template_card.template_datum_id,
                        created_by: current_user.id,
                        updated_by: current_user.id
                    })
                    payload["api_slug"] = profile_card.datacast_identifier
                    payload["schema_url"] = profile_card.template_datum.schema_json
                    payload["bucket_name"] = ceew_site.cdn_bucket
                    r = Api::ProtoGraph::Datacast.create(payload)
                    if r.has_key?("errorMessage")
                        profile_card.destroy
                        puts r['errorMessage']
                        puts "================="
                    else
                        puts "Saved #{da}"
                    end

                    StreamEntity.create({
                        stream_id: narrative_stream.id,
                        entity_type: "view_cast_id",
                        entity_value: "#{profile_card.id}",
                        created_by: current_user.id,
                        updated_by: current_user.id,
                        sort_order: start_sort_order
                    })
                end

                StreamEntity.create({
                    stream_id: narrative_stream.id,
                    entity_type: "view_cast_id",
                    entity_value: "#{policy_para_id}",
                    created_by: current_user.id,
                    updated_by: current_user.id,
                    sort_order: start_sort_order
                })

                policy_map.each do |da, mapping|
                    unless d[da].blank?
                        puts da
                        puts "++++++++++++++"
                        #Create Drilldown card
                        is_recommended_text = ""
                        title = "#{headline} - #{da}"
                        datacast_params = {data: {
                            "title": "#{da}",
                            "verdict": "#{is_recommended_text}",
                            "description": d[da],
                            "district": d["district"],
                            "parameters": []
                        }}

                        mapping.each do |parameter, v|
                            obj = {}
                            obj["title"] = parameter
                            obj["display"] = "#{d[v[0]]}"
                            obj["percentile"] = "#{d[v[1]]}"
                            datacast_params[:data][:parameters] << obj
                        end



                        payload = {}
                        payload["payload"] = datacast_params.to_json
                        payload["source"]  = "form"
                        profile_card = ViewCast.create({
                            site_id: ceew_site.id,
                            account_id: ceew_account.id,
                            name: title,
                            seo_blockquote: "",
                            folder_id: district_policy_folder.id,
                            ref_category_vertical_id: district_policy_folder.ref_category_vertical_id,
                            template_card_id: drilldown_template_card.id,
                            template_datum_id:  drilldown_template_card.template_datum_id,
                            created_by: current_user.id,
                            updated_by: current_user.id
                        })
                        payload["api_slug"] = profile_card.datacast_identifier
                        payload["schema_url"] = profile_card.template_datum.schema_json
                        payload["bucket_name"] = ceew_site.cdn_bucket

                        r = Api::ProtoGraph::Datacast.create(payload)
                        if r.has_key?("errorMessage")
                            profile_card.destroy
                            puts r['errorMessage']
                            puts "================="
                        else
                            puts "Saved #{da}"
                        end

                        StreamEntity.create({
                            stream_id: narrative_stream.id,
                            entity_type: "view_cast_id",
                            entity_value: "#{profile_card.id}",
                            created_by: current_user.id,
                            updated_by: current_user.id,
                            sort_order: start_sort_order
                        })
                    end
                end

                narrative_stream.publish_cards
                response = Api::ProtoGraph::Page.create_or_update_page(page.datacast_identifier, page.template_page.s3_identifier, ceew_site.cdn_bucket, ENV['AWS_S3_ENDPOINT'])
            end
        end
    end


    task fix_profile_card: :environment do
        ceew_account = Rails.env.development? ? Account.friendly.find('pykih') : Account.friendly.find('ceew')
        ceew_site = ceew_account.site
        t_profile_card = TemplateCard.where(name: "toProfile").first

        t_profile_card.view_casts.where(site_id: ceew_site.id).each do |view_cast|
            puts view_cast.name
            puts "=============="
            cards_json = JSON.parse(RestClient.get(view_cast.data_url).body)
            cards_json['data']['details'].last['key'] =  "Parameters (Value, Percentile)"

            encoded_file = Base64.encode64(cards_json.to_json)
            content_type = "application/json"
            resp = Api::ProtoGraph::Utility.upload_to_cdn(encoded_file, "#{view_cast.datacast_identifier}/data.json", content_type, ceew_site.cdn_bucket)
        end

        Api::ProtoGraph::CloudFront.invalidate(ceew_site, ["*"], 1)

    end
end