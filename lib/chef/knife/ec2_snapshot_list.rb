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
    class Ec2SnapshotList < Knife

      include Knife::Ec2Base

      banner "knife ec2 snapshot list (options)"
      
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
          list_instance(connection.snapshots.get(Chef::Config[:knife][:instance]))
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
          snapshot_list = list_snapshots(region)

          puts "Listing snapshots in region #{region}"
          puts ui.list(snapshot_list, :uneven_columns_across, 8)
        end

      end
      
      def list_snapshots(region = nil)
        snapshot_list = ["ID", "Volume ID", "Name", "Size", "Description", "Created", "Progress", "State"]
        snapshot_list.map!{ |f| ui.color(f, :bold) }
        connection(region).snapshots.all.each do |snapshot|
          snapshot_list << snapshot.id.to_s
          snapshot_list << snapshot.volume_id.to_s
          snapshot_list << snapshot.tags["Name"].to_s
          snapshot_list << "#{snapshot.volume_size.to_s}G"
          snapshot_list << snapshot.description.to_s
          snapshot_list << snapshot.created_at.to_s
          snapshot_list << snapshot.progress.to_s
          snapshot_list << color_state(:snapshot, snapshot.state.to_s)
        end
        
        return snapshot_list
      end
    end
  end
end