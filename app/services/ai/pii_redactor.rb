module Ai
  # PII(개인식별정보) 익명화 서비스
  # LLM에 전송하기 전 개인정보를 마스킹하고, 응답에서 복원
  class PiiRedactor
    # PII 패턴 정의
    PATTERNS = {
      # 한국식 이름 (2-4글자 한글)
      korean_name: {
        pattern: /([가-힣]{2,4})(?=\s*(학생|님|씨|군|양|이|가|은|는|을|를|의|에게|께))/,
        placeholder: "[이름]"
      },
      # 이메일
      email: {
        pattern: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/,
        placeholder: "[이메일]"
      },
      # 전화번호 (한국)
      phone: {
        pattern: /(?:010|011|016|017|018|019)[-.\s]?\d{3,4}[-.\s]?\d{4}/,
        placeholder: "[전화번호]"
      },
      # 주민등록번호
      ssn: {
        pattern: /\d{6}[-\s]?\d{7}/,
        placeholder: "[주민번호]"
      },
      # 학교명 (초/중/고)
      school: {
        pattern: /[가-힣]+(?:초등학교|중학교|고등학교|초|중|고)/,
        placeholder: "[학교]"
      },
      # 학번/학생코드
      student_id: {
        pattern: /(?:학번|학생번호|코드)[:\s]*[A-Za-z0-9-]+/,
        placeholder: "[학번]"
      },
      # 주소 패턴 (간단화)
      address: {
        pattern: /(?:[가-힣]+(?:시|도|구|군|읍|면|동|리|로|길)\s*)+\d+(?:[-\s]\d+)?/,
        placeholder: "[주소]"
      }
    }.freeze

    def initialize
      @mappings = {}
      @counter = 0
    end

    # 텍스트에서 PII 익명화
    # @param text [String] 원본 텍스트
    # @param context [Hash] 추가 컨텍스트 (학생 이름 등)
    # @return [String] 익명화된 텍스트
    def redact(text, context: {})
      return "" if text.blank?

      result = text.dup

      # 컨텍스트에서 알려진 이름 우선 처리
      if context[:student_name].present?
        name = context[:student_name]
        placeholder = generate_placeholder("NAME")
        @mappings[placeholder] = name
        result = result.gsub(name, placeholder)
      end

      # 패턴 기반 익명화
      PATTERNS.each do |type, config|
        result = result.gsub(config[:pattern]) do |match|
          # 이미 매핑된 값인지 확인
          existing = @mappings.key(match)
          if existing
            existing
          else
            placeholder = generate_placeholder(type.to_s.upcase)
            @mappings[placeholder] = match
            placeholder
          end
        end
      end

      result
    end

    # 익명화된 텍스트를 원본으로 복원
    # @param text [String] 익명화된 텍스트
    # @return [String] 복원된 텍스트
    def restore(text)
      return "" if text.blank?

      result = text.dup
      @mappings.each do |placeholder, original|
        result = result.gsub(placeholder, original)
      end
      result
    end

    # 해시 구조 내의 모든 문자열 익명화
    # @param data [Hash, Array, String] 익명화할 데이터
    # @param context [Hash] 추가 컨텍스트
    # @return [Hash, Array, String] 익명화된 데이터
    def redact_deep(data, context: {})
      case data
      when Hash
        data.transform_values { |v| redact_deep(v, context: context) }
      when Array
        data.map { |v| redact_deep(v, context: context) }
      when String
        redact(data, context: context)
      else
        data
      end
    end

    # 해시 구조 내의 모든 문자열 복원
    # @param data [Hash, Array, String] 복원할 데이터
    # @return [Hash, Array, String] 복원된 데이터
    def restore_deep(data)
      case data
      when Hash
        data.transform_values { |v| restore_deep(v) }
      when Array
        data.map { |v| restore_deep(v) }
      when String
        restore(data)
      else
        data
      end
    end

    # 현재 매핑 정보 반환 (디버그용)
    def mappings
      @mappings.dup
    end

    # 매핑 정보 직렬화 (세션 간 유지용)
    def serialize_mappings
      @mappings.to_json
    end

    # 매핑 정보 복원
    def load_mappings(json)
      @mappings = JSON.parse(json)
    rescue JSON::ParserError
      @mappings = {}
    end

    private

    def generate_placeholder(type)
      @counter += 1
      "[#{type}_#{@counter}]"
    end
  end
end
