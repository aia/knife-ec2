#
# Author:: Artem Veremey (<artem@veremey.net>)
# Copyright:: Copyright (c) Artem Veremey
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
    class Ec2VolumeList < Knife

      include Knife::Ec2Base

      banner "knife ec2 volume list (options)"
      
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
          list_instance(connection.volumes.get(Chef::Config[:knife][:instance]))
          exit
        end
        
        regions = []
        if Chef::Config[:knife][:allregions]
          connection.describe_regions.body["regionInfo"].each do |region|
            regions << region["regionName"]
          end
        else
          regions << locate_config_value(:aws_region)
        end

        regions.each do |region|
          volume_list = list_volumes(region)

          puts "Listing volumes in region #{region}"
          puts ui.list(volume_list, :uneven_columns_across, 6)
        end

      end
      
      def list_volumes(region = nil)
        volume_list = ["ID", "Zone", "Size", "Server ID", "Created", "State"]
        volume_list.map!{ |f| ui.color(f, :bold) }
        connection(region).volumes.all.each do |volume|
          volume_list << volume.id.to_s
          volume_list << volume.availability_zone.to_s
          volume_list << [volume.size.to_s, "G"].join
          volume_list << volume.server_id.to_s
          volume_list << volume.created_at.to_s
          volume_list << color_state(:volume, volume.state.to_s)
        end
        
        return volume_list
      end
    end
  end
end


