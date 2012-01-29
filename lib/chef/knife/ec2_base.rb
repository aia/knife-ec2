#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'

class Chef
  class Knife
    module Ec2Base

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'readline'
            require 'chef/json_compat'
          end

          option :aws_access_key_id,
            :short => "-A ID",
            :long => "--aws-access-key-id KEY",
            :description => "Your AWS Access Key ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:set_aws_access_key_id] = key }

          option :aws_secret_access_key,
            :short => "-K SECRET",
            :long => "--aws-secret-access-key SECRET",
            :description => "Your AWS API Secret Access Key",
            :proc => Proc.new { |key| Chef::Config[:knife][:set_aws_secret_access_key] = key }

          option :region,
            :long => "--region REGION",
            :description => "Your AWS region",
            :default => "us-east-1",
            :proc => Proc.new { |key| Chef::Config[:knife][:set_region] = key }
        end
      end

      def connection
        @connection ||= Fog::Compute.new(
          :provider => 'AWS',
          :aws_access_key_id => locate_config_value(:aws_access_key_id),
          :aws_secret_access_key => locate_config_value(:aws_secret_access_key),
          :region => locate_config_value(:region)
        )
      end

      def locate_config_value(key)
        key = key.to_sym
        set_key = ["set_", key].join.to_sym
        
        ret = Chef::Config[:knife][set_key].nil? ? Chef::Config[:knife][key] : Chef::Config[:knife][set_key]
        ret = ret.nil? ? config[key] : ret
        
        if (ret.nil?)
          ui.error("Required configuration variable not set: #{key}")
          exit 1
        end
        
        return ret
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def validate!(keys=[:aws_access_key_id, :aws_secret_access_key])
        # errors = []
        # 
        # keys.each do |k|
        #   pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
        #   if Chef::Config[:knife][k].nil?
        #     errors << "You did not provide a valid '#{pretty_key}' value."
        #   end
        # end
        # 
        # if errors.each{|e| ui.error(e)}.any?
        #   exit 1
        # end
      end
      
      def color_state(state)
        case state
        when 'shutting-down','terminated','stopping','stopped'
          ui.color(state, :red)
        when 'pending'
          ui.color(state, :yellow)
        else
          ui.color(state, :green)
        end
      end

    end
  end
end


