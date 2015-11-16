require 'rspec/core/formatters/base_formatter'
require 'fileutils'

module AllureRSpec

  class Formatter < RSpec::Core::Formatters::BaseFormatter

    ALLOWED_LABELS = [:feature, :story, :severity, :language, :framework]

    def example_failed(example)
      AllureRubyAdaptorApi::Builder.stop_test(
          example.metadata[:example_group][:description_args].first,
          example.metadata[:description],
          example.metadata[:execution_result].merge(
              :caller => example.metadata[:caller],
              :exception => example.metadata[:execution_result][:exception]
          )
      )
      super
    end

    def example_group_finished(group)
      AllureRubyAdaptorApi::Builder.stop_suite(group.metadata[:example_group][:description_args].first)
      super
    end

    def example_group_started(group)
      label_dict = labels(group)
      label_dict[:thread] = Thread.current.object_id + ENV['TEST_ENV_NUMBER'].to_i
      AllureRubyAdaptorApi::Builder.start_suite(group.metadata[:example_group][:description_args].first, label_dict)
      super
    end

    def example_passed(example)
      AllureRubyAdaptorApi::Builder.stop_test(
          example.metadata[:example_group][:description_args].first,
          example.metadata[:description],
          example.metadata[:execution_result].merge(:caller => example.metadata[:caller])
      )
      super
    end

    def example_pending(example)
      AllureRubyAdaptorApi::Builder.stop_test(
          example.metadata[:example_group][:description_args].first,
          example.metadata[:description],
          :status => :pending
      )
      super
    end

    def example_started(example)
      label_dict = labels(example)
      label_dict[:thread] = Thread.current.object_id + ENV['TEST_ENV_NUMBER'].to_i
      suite = example.metadata[:example_group][:description_args].first
      test = example.metadata[:description]
      AllureRubyAdaptorApi::Builder.start_test(suite, test, label_dict)
      super
    end

    def start(example_count)
      dir = Pathname.new(AllureRSpec::Config.output_dir)
      if AllureRSpec::Config.clean_dir?
        puts "Cleaning output directory '#{dir}'..."
        FileUtils.rm_rf(dir)
      end
      FileUtils.mkdir_p(dir)
      super
    end

    def stop
      AllureRubyAdaptorApi::Builder.build!
      super
    end

    private

    def labels(example_or_group)
      ALLOWED_LABELS.
          map { |label| [label, example_or_group.metadata[label]] }.
          find_all { |value| !value[1].nil? }.
          inject({}) { |res, value| res.merge(value[0] => value[1]) }
      
    end

  end
end
