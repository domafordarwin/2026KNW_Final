module ApplicationHelper
  # 영역명을 한글 라벨로 변환
  def domain_label(domain)
    labels = {
      "decoding" => "해독", "vocabulary" => "어휘", "fluency" => "유창성",
      "comprehension" => "독해", "inference" => "추론", "literal" => "사실적 이해",
      "critical" => "비판적 이해", "creative" => "창의적 이해"
    }
    labels[domain.to_s] || domain.to_s.humanize
  end

  # 등급별 색상 반환
  def grade_color(grade)
    colors = {
      "A+" => "linear-gradient(180deg, #66bb6a 0%, #43a047 100%)",
      "A" => "linear-gradient(180deg, #66bb6a 0%, #43a047 100%)",
      "A-" => "linear-gradient(180deg, #81c784 0%, #66bb6a 100%)",
      "B+" => "linear-gradient(180deg, #9ccc65 0%, #7cb342 100%)",
      "B" => "linear-gradient(180deg, #9ccc65 0%, #7cb342 100%)",
      "B-" => "linear-gradient(180deg, #aed581 0%, #9ccc65 100%)",
      "C+" => "linear-gradient(180deg, #ffee58 0%, #fdd835 100%)",
      "C" => "linear-gradient(180deg, #ffee58 0%, #fdd835 100%)",
      "C-" => "linear-gradient(180deg, #fff176 0%, #ffee58 100%)",
      "D+" => "linear-gradient(180deg, #ffa726 0%, #fb8c00 100%)",
      "D" => "linear-gradient(180deg, #ffa726 0%, #fb8c00 100%)",
      "D-" => "linear-gradient(180deg, #ffb74d 0%, #ffa726 100%)",
      "F" => "linear-gradient(180deg, #ef5350 0%, #e53935 100%)"
    }
    colors[grade.to_s] || "linear-gradient(180deg, #42a5f5 0%, #1976d2 100%)"
  end

  # 중첩된 해시에서 dot notation 키로 값을 가져옴
  def get_nested_value(hash, path)
    return nil unless hash.is_a?(Hash)
    path.to_s.split('.').reduce(hash) do |current, key|
      return nil unless current.is_a?(Hash)
      current[key] || current[key.to_sym]
    end
  end

  # diff_json에서 특정 키가 수정되었는지 확인
  def has_diff?(diff_json, key)
    return false unless diff_json.is_a?(Hash)
    diff_json.key?(key) || diff_json.key?(key.to_sym)
  end

  # 주석 데이터 가져오기
  def get_annotations(content, section_key)
    return [] unless content.is_a?(Hash)
    annotations = content['_annotations'] || content[:_annotations] || {}
    annotations[section_key] || annotations[section_key.to_sym] || []
  end
end
