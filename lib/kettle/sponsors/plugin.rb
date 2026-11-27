# frozen_string_literal: true

module Kettle
  module Sponsors
    # kettle-jem plugin: renders locally-hosted badges after template files exist.
    # Central badges need no files; they are referenced by URL.
    module Plugin
      module_function

      def register!(registrar)
        registrar.after_phase(:remaining_files) do |context:, **|
          render_local(context)
        end
      end

      def render_local(context)
        config_path = File.join(context.project_root, CONFIG_PATH)
        loaded = Config.load_all(config_path)
        local = loaded[:sponsors].select(&:local?)
        return if local.empty?

        out = File.join(context.project_root, LOCAL_DIR)
        Renderer.render(local, out: out, theme: loaded[:theme], base_dir: context.project_root).each do |path|
          context.helpers.record_template_result(path, :replace)
        end
        context.out.report_detail("[kettle-sponsors] #{local.size} local sponsor badge(s) up to date")
      rescue Error => e
        context.out.warning("[kettle-sponsors] #{e.message}")
      end
    end
  end
end
