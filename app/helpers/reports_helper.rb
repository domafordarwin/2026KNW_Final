module ReportsHelper
  def report_bar(value, max: 100)
    value = value.to_f
    max = max.to_f
    width = max.zero? ? 0 : ((value / max) * 100).clamp(0, 100)
    bar = content_tag(:div, "", class: "report-bar__fill", style: "width: #{width}%")
    content_tag(:div, bar, class: "report-bar") + content_tag(:span, " #{value}")
  end
end
