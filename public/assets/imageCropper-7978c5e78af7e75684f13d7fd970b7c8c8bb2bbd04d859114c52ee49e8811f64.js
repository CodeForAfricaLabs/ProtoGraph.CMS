function readURL(t){if(t.files&&t.files[0]){var a=new FileReader;a.onload=function(a){JCropInstance&&(JCropInstance.destroy(),$("#cropbox").attr("src",""),$("#cropbox").attr("style","")),$(".protograph-new-image").css("display","block"),$("#image_name").val(t.files[0].name.replace(/\.[^\/.]+$/,"")),$("#cropbox").attr("src",a.target.result),setTimeout(function(){var t=$("#cropbox")[0];$("#cropbox").Jcrop({setSelect:[0,0,420,420],onSelect:update,onChange:update,boxHeight:350,boxWidth:500,trueSize:[t.naturalWidth,t.naturalHeight],aspectRatio:$("#aspectRatioMenu li.item.active").data().width/$("#aspectRatioMenu li.item.active").data().height},function(){JCropInstance=this})},0)},a.readAsDataURL(t.files[0])}else $("#cropbox").attr("src",""),$("#image_name").val("")}function update(t){$(".jcrop-holder .protograph-crop-tooltip").length||$(".jcrop-holder").append('<div class="protograph-crop-tooltip"></div>'),$("#image_crop_x").val(t.x),$("#image_crop_y").val(t.y),$("#image_crop_w").val(t.w),$("#image_crop_h").val(t.h),$("#new_image_submit_button").hasClass("protograph-disabled-button")&&$("#new_image_submit_button").removeClass("protograph-disabled-button");var a="",e=Math.round(t.w),o=Math.round(t.h),i=e/gcd(e,o),r=o/gcd(e,o);t.w>0&&t.h>0?(a+=e+" x "+o,a+="  ",a+="("+Math.round(i)+":"+Math.round(r)+")"):a+=e+" x "+o,$(".protograph-crop-tooltip").html(a)}var gcd=function(t,a){return a?gcd(a,t%a):t};$(document).ready(function(){$("#aspectRatioMenu li.item").on("click",function(t){if("disabled"===$(this).attr("disabled"))return!1;var a,e,o=$(this);o.addClass("active").siblings(".item").removeClass("active"),a=o.data(),e=a.height>0&&a.width>0?a.width/a.height:0;var i=$("#cropbox")[0];$("#cropbox").Jcrop({setSelect:[0,0,420,420],onSelect:update,onChange:update,boxHeight:350,boxWidth:500,aspectRatio:e,trueSize:[i.naturalWidth,i.naturalHeight]},function(){JCropInstance=this}),t.preventDefault()}),$("#new_image").submit(function(){return $("#ui_dimmer").addClass("active"),!0}),$("#new_image").on("ajax:success",function(t){var a=t.detail[0];$("#image_url_container").css("display","block"),$("#photo_url").val(a.data.image_url),$("#photo_url").focus(),$("#photo_url").select(),$("#ui_dimmer").removeClass("active")}).on("ajax:error",function(t){var a=t.detail[0];a.constructor===String?showAllValidationErrors(a):showAllValidationErrors(a.errors),$("#ui_dimmer").removeClass("active"),$("#image_url_container").css("display","block")}),$("#protograph_image_bank_button").on("click",function(){$("#new_image")[0].reset(),$("#image_url_container").css("display","none"),JCropInstance&&JCropInstance.destroy(),$("#aspectRatioMenu li.item.active").removeClass("active"),$("#aspectRatioMenu li.item:first").addClass("active"),$("#image_container").css("display","none")})});