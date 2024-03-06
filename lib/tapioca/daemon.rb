# frozen_string_literal: true

require_relative "daemon/version"

require 'listen'
require 'tapioca'
require 'tapioca/internal'
# パッチを当てたいのでロードしておく
require "tapioca/dsl/helpers/active_record_column_type_helper"
# require 'tapioca/runner'

::Tapioca::Dsl::Helpers::ActiveRecordColumnTypeHelper.class_eval do
  private

  sig { returns([String, String]) }
  def id_type
    if @constant.respond_to?(:composite_primary_key?) && T.unsafe(@constant).composite_primary_key?
      @constant.primary_key.map(&method(:column_type_for)).map { |tuple| "[#{tuple.join(", ")}]" }
    else
      # ↓pkない場合のパッチ
      column_type_for(@constant.primary_key || @constant.attribute_names.first)
    end
  end
end


module Tapioca
  class Daemon
    def initialize
      loader = Tapioca::Loaders::Dsl.new(tapioca_path: 'sorbet/tapioca', eager_load: true, app_root: '.', halt_upon_load_error: true)
      loader.send(:load_dsl_extensions)
      loader.send(:load_application)

      begin
        @listener = Listen.to('app', 'spec', 'sorbet/tapioca/compilers', wait_for_delay: 3) do |modified, added, removed|
          files = modified + added + removed

          puts "Detected changes on #{files.join(", ")}, running dsl compilers..."
          Process.wait(run_tapioca_dsl(files, loader))
        end
      rescue => e
        pp e
        pp e.backtrace
        puts "Error!!! retrying"
        sleep(1)
        retry
      end
    end

    def run_tapioca_dsl(files, loader)
      child_pid = fork do
        start_at = Time.now
        ::Rails.application.reloader.reload!
        loader.send(:load_dsl_compilers)
        ::Tapioca::Commands::DslGenerate.new(
          requested_constants: [],
          requested_paths: [],#files.map { Pathname.new(_1) },
          outpath: Pathname.new(Tapioca::DEFAULT_DSL_DIR),
          rbi_formatter: Tapioca::DEFAULT_RBI_FORMATTER.then { _1.max_line_length = Tapioca::DEFAULT_RBI_MAX_LINE_LENGTH },
          number_of_workers: 72,
          only: [],
          exclude: [],
          file_header: true,
          tapioca_path:Tapioca::TAPIOCA_DIR
        ).run
        puts "took #{(Time.now - start_at)} seconds to run compile"
      end

      child_pid
    rescue => e
      puts "Error running Tapioca: #{e.message}"
    end

    def start
      @listener.start # not blocking
      puts "TapiocaDaemon started. Watching for file changes..."
      sleep
    end
  end
end
