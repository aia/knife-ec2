#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Artem Veremey (<artem@veremey.net>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require 'chef/knife/ec2_base'
require 'active_support/inflector'

class Chef
  class Knife
    class Ec2ServerList < Knife

      include Knife::Ec2Base

      banner "knife ec2 server list (options)"
      
      option :allregions,
        :short => "--all",
        :long => "--all-regions",
        :boolean => true,
        :description => "List servers in all regions",
        :proc => Proc.new { |f| Chef::Config[:knife][:allregions] = f }
        
       option :instance,
          :instance => "-i INSTANCE_ID",
          :long => "--instance INSTANCE_ID",
          :description => "Optional instance id",
          :proc => Proc.new { |f| Chef::Config[:knife][:instance] = f }

      def run
        $stdout.sync = true

        validate!
        
        if Chef::Config[:knife][:instance]
          list_server(Chef::Config[:knife][:instance])
          exit
        end
        
        regions = []
        if Chef::Config[:knife][:allregions]
          connection.describe_regions.body["regionInfo"].each do |region|
            regions << region["regionName"]
          end
        else
          regions << locate_config_value(:region)
        end

        regions.each do |region|
          server_list = list_servers(region)

          puts "Listing instances in region #{region}"
          puts ui.list(server_list, :uneven_columns_across, 10)
        end

      end
      
      def list_servers(region = nil)
        server_list = ["Instance ID", "Name", "Zone", "Public IP", "Private IP",
          "Flavor", "Image", "SSH Key", "Sec Group", "State"]
        
        server_list.map!{ |f| ui.color(f, :bold) }
        
        connection(region).servers.all.each do |server|
          server_list << server.id.to_s
          server_list << server.tags["Name"].to_s
          server_list << server.availability_zone.to_s
          server_list << server.public_ip_address.to_s
          server_list << server.private_ip_address.to_s
          server_list << server.flavor_id.to_s
          server_list << server.image_id.to_s
          server_list << server.key_name.to_s
          server_list << "[#{server.groups.values_at(* server.groups.each_index.select {|i| i.odd?}).join(', ')}]"
          server_list << color_state(:server, server.state.to_s.downcase)
        end
        
        return server_list
      end
      
      def list_server(instance)
        table = []
        result = connection.servers.get(instance).inspect
        result.split("\n")[1..-2].each do |line|
          match = /(?<key>.+?)=(?<value>.+)/.match(line)
          table << ui.color(match[:key].gsub(/\s+/, "").titleize, :cyan) << match[:value].gsub(/,$/, "")
        end
        
        puts ui.list(table, :uneven_columns_across, 2)
      end
    end
  end
end

