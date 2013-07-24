# -*- coding: utf-8 -*-
module Jekyll
  module Commands
    class Serve < Command
      def self.process(options)
        require 'open3'
        require 'webrick'
        include WEBrick

        destination = options['destination']

        FileUtils.mkdir_p(destination)

        mime_types_file = File.expand_path('../mime.types', File.dirname(__FILE__))
        mime_types = WEBrick::HTTPUtils::load_mime_types(mime_types_file)

        # recreate NondisclosureName under utf-8 circumstance
        fh_option = WEBrick::Config::FileHandler
        fh_option[:NondisclosureName] = ['.ht*','~*']

        s = HTTPServer.new(
          :Port => options['port'],
          :BindAddress => options['host'],
          :MimeTypes => mime_types
        )

        s.mount_proc '/git/status' do |req, res|
          stdin, stdout, stderr = Open3.popen3('git status')
          res.body = "stdout:\n#{stdout.read}\n\nstderr:\n#{stderr.read}\n"
        end

        s.mount_proc '/git/log' do |req, res|
          stdin, stdout, stderr = Open3.popen3('git log')
          res.body = "stdout:\n#{stdout.read}\n\nstderr:\n#{stderr.read}\n"
        end

        s.mount_proc '/git/pull' do |req, res|
          stdin, stdout, stderr = Open3.popen3('git pull origin master')
          res.body = "stdout:\n#{stdout.read}\n\nstderr:\n#{stderr.read}\n"
        end

        s.mount(options['baseurl'], HTTPServlet::FileHandler, destination, fh_option)
        t = Thread.new { s.start }
        trap("INT") { s.shutdown }
        t.join()
      end
    end
  end
end
