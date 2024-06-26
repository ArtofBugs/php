#
# Author:: Seth Chisamore <schisamo@chef.io>
# Author:: Jennifer Davis <sigje@chef.io>
# Cookbook:: php
# Resource:: pear_channel
#
# Copyright:: 2011-2021, Chef Software, Inc <legal@chef.io>
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

unified_mode true

property :channel_xml, String
property :channel_name, String, name_property: true
property :binary, String, default: 'pear'

action :discover do
  unless exists?
    Chef::Log.info("Discovering pear channel #{new_resource}")
    execute "#{new_resource.binary} channel-discover #{new_resource.channel_name}"
  end
end

action :add do
  unless exists?
    Chef::Log.info("Adding pear channel #{new_resource} from #{new_resource.channel_xml}")
    execute "#{new_resource.binary} channel-add #{new_resource.channel_xml}"
  end
end

action :update do
  if exists? && update_needed?
    converge_by("update pear channel #{new_resource}") do
      Chef::Log.info("Updating pear channel #{new_resource}")
      shell_out!("#{new_resource.binary} channel-update #{new_resource.channel_name}")
    end
  end
end

action :remove do
  if exists?
    Chef::Log.info("Deleting pear channel #{new_resource}")
    execute "#{new_resource.binary} channel-delete #{new_resource.channel_name}"
  end
end

action_class do
  # determine if the channel needs to be updated by searching for a bogus package
  # in that channel and looking for the text prompting the user to update the channel
  # in the CLI output
  # @return [Boolean] does the channel need to be updated
  def update_needed?
    begin
      if shell_out("#{new_resource.binary} search -c #{new_resource.channel_name} NNNNNN").stdout =~ /channel-update/
        return true
      end
    rescue Chef::Exceptions::CommandTimeout
      # CentOS can hang on 'pear search' if a channel needs updating
      Chef::Log.info("Timed out checking if channel-update needed...forcing update of pear channel #{new_resource.channel_name}")
      return true
    end
    false
  end

  # run pear channel-info to see if the channel has been setup or not
  # @return [Boolean] does the channel exist locally
  def exists?
    shell_out!("#{new_resource.binary} channel-info #{new_resource.channel_name}")
    true
  rescue Mixlib::ShellOut::ShellCommandFailed
    false
  end
end
