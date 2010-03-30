module Integrity
  module Helpers
    module Xml
    
      def xml_opts_for_project(project)
        opts = {}
        opts['name']     = project.name
        opts['category'] = project.branch
        opts['activity'] = activity(project.last_build.status) if project.last_build
        opts['webUrl']   = project_url(project).to_s.gsub(request.script_name, '')
        if project.last_build
          opts['lastBuildStatus'] = build_status(project.last_build.status)
          opts['lastBuildLabel']  = project.last_build.commit.short_identifier
          opts['lastBuildTime']   = project.last_build.completed_at
        end
        opts
      end

      def activity(status)
        case status
          when :success, :failed then
            'Sleeping'
          when :pending, :building then
            'Building'
          else
            'Sleeping'
        end
      end

      def build_status(status)
        case status
          when :success, :pending then
            'Success'
          when :failed then
            'Failure'
          else
            'Unknown'
        end
      end

    end
  end
end