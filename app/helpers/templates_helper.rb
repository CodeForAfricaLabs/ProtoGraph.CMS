module TemplatesHelper

    def show_lock(s, str)
        if s
            return ""
        else
            return "#{str} <i class='lock icon' style='color: gold; font-size: 15px;'></i>"
        end
    end

end