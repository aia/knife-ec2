require 'chef/knife/ec2_base'

class Chef
  class Knife
    class Ec2ServerStop < Knife

      include Knife::Ec2Base

      banner "knife ec2 server stop -i instance-id (options)"
      
      option :instance,
        :instance => "-i INSTANCE_ID",
        :long => "--instance INSTANCE_ID",
        :description => "Your instance id",
        :proc => Proc.new { |f| Chef::Config[:knife][:instance] = f }
      
      def run
        $stdout.sync = true

        validate!
        
        if Chef::Config[:knife][:instance].nil?
          ui.error("Instance ID not specified")
          exit 1
        end

        require 'pp'
        
        instance_ids = connection.servers.map{ |server| server.id }
        
        unless instance_ids.include?(Chef::Config[:knife][:instance])
          ui.error("Invalid instance id: #{Chef::Config[:knife][:instance]}")
          puts "Existing instances: #{instance_ids.join(", ")}"
          exit 1
        end
        
        result = connection.stop_instances([Chef::Config[:knife][:instance]])
        
        # #<Excon::Response:0x007fe3fb1ac430
        #  @body=
        #   {"instancesSet"=>
        #     [{"currentState"=>{"code"=>"64", "name"=>"stopping"},
        #       "previousState"=>{"code"=>"16", "name"=>"running"},
        #       "instanceId"=>"i-34631804"}]},
        #  @headers=
        #   {"Content-Type"=>"text/xml;charset=UTF-8",
        #    "Transfer-Encoding"=>"chunked",
        #    "Date"=>"Sun, 29 Jan 2012 07:17:19 GMT",
        #    "Server"=>"AmazonEC2"},
        #  @status=200>
        
        
        # #<Excon::Response:0x007fa079380f10
        #  @body=
        #   {"instancesSet"=>
        #     [{"currentState"=>{"code"=>"16", "name"=>"running"},
        #       "previousState"=>{"code"=>"16", "name"=>"running"},
        #       "instanceId"=>"i-34631804"}]},
        #  @headers=
        #   {"Content-Type"=>"text/xml;charset=UTF-8",
        #    "Transfer-Encoding"=>"chunked",
        #    "Date"=>"Sun, 29 Jan 2012 07:15:45 GMT",
        #    "Server"=>"AmazonEC2"},
        #  @status=200>
        
        
        res = result.body["instancesSet"].first
        
        msg = []
        msg << "Instance #{Chef::Config[:knife][:instance]} previous state "
        msg << color_state(res["previousState"]["name"])
        msg << "Instance #{Chef::Config[:knife][:instance]} current state "
        msg << color_state(res["currentState"]["name"])
        
        puts ui.list(msg, :columns_across, 2)

      end
      
    end
  end
end