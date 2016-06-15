module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, repository: nil, plain: false)
      new(blob_name, blob_content, repository: repository).
        highlight(blob_content, continue: false, plain: plain)
    end

    def self.highlight_lines(repository, ref, file_name)
      blob = repository.blob_at(ref, file_name)
      return [] unless blob

      blob.load_all_data!(repository)
      highlight(file_name, blob.data, repository: repository).lines.map!(&:html_safe)
    end

    def initialize(blob_name, blob_content)
      @formatter = Rouge::Formatters::HTMLGitlab.new
      @repository = repository
      @lexer = custom_language || begin
        Rouge::Lexer.guess(filename: blob_name, source: blob_content).new
      rescue Rouge::Lexer::AmbiguousGuess => e
        e.alternatives.sort_by(&:tag).first
      end
    end

    def highlight(text, continue: true, plain: false)
      lexer = @lexer

      if plain
        lexer = Rouge::Lexers::PlainText
        continue = false
      end

      @formatter.format(@lexer.lex(text, continue: continue)).html_safe
    rescue
      @formatter.format(Rouge::Lexers::PlainText.lex(text)).html_safe
    end

    private

    def custom_language
      language_name = @repository && @repository.gitattribute(@blob_name, 'gitlab-language')

      return nil unless language_name

      Rouge::Lexer.find_fancy(language_name)
    end
  end
end
