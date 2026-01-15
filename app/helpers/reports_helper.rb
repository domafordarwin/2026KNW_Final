module ReportsHelper
  def report_bar(value, max: 100)
    value = value.to_f
    max = max.to_f
    width = max.zero? ? 0 : ((value / max) * 100).clamp(0, 100)
    bar = content_tag(:div, "", class: "report-bar__fill", style: "width: #{width}%")
    content_tag(:div, bar, class: "report-bar") + content_tag(:span, " #{value}")
  end

  def report_section_visible?(audience, section_id)
    hidden_for_parent = %w[S-06 S-07 S-12]
    hidden_for_student = %w[S-07 S-12]

    case audience
    when "parent"
      !hidden_for_parent.include?(section_id)
    when "student"
      !hidden_for_student.include?(section_id)
    else
      true
    end
  end

  def display_student_name(student, audience)
    return "" unless student
    return student.name if %w[parent teacher].include?(audience)

    name = student.name.to_s
    return name if name.length < 2

    "#{name[0]}**"
  end
end
