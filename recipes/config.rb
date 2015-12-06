#
# Cookbook Name:: gearman-job-server
# Recipe:: config
#
# Copyright (c) 2015 Chris Zeeb <chris.zeeb@gmail.com>
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

# Map parameters and discard nil k/v pairs
params = node['gearman-job-server']['parameters'].reject { |_k, v| v.nil? }.map { |k, v| "--#{k}=#{v}" }.join(' ')

# If a persistent queue-type is set, add the queue types parameters in and discard nil k/v pairs.
# TODO: Create connection string for libpg for user rather than them having to build it
if node['gearman-job-server']['parameters']['queue-type']
  queuetype = node['gearman-job-server']['parameters']['queue-type']
  queuetype = 'libpq' if queuetype == 'Postgres'

  # We want to ignore the libpq conninfo parameter for Ubuntu 12.04. It needs to go in the init script instead
  if node['platform'] == 'ubuntu' && node['platform_version'] == '12.04' && queuetype == 'libpq'
    params = params + ' ' + node['gearman-job-server'][queuetype].reject { |k, v| v.nil? || k == 'conninfo' }.map { |k, v| "--#{queuetype}-#{k}=#{v}" }.join(' ')
  else
    params = params + ' ' + node['gearman-job-server'][queuetype].reject { |_k, v| v.nil? }.map { |k, v| "--#{queuetype}-#{k}=#{v}" }.join(' ')
  end
end

# TODO: Add toggle for if gearman should be restarted when config changes.
template 'gearman-config' do
  source 'gearman-config.erb'
  case node['platform_family']
  when 'debian'
    path '/etc/default/gearman-job-server'
    variables(
      :param_word => 'PARAMS',
      :params     => params
    )
  when 'rhel'
    path '/etc/sysconfig/gearmand'
    variables(
      :param_word => 'OPTIONS',
      :params     => params
    )
  end
end

if node['platform'] == 'ubuntu' && node['platform_family'] == '12.04'
  template 'gearmand-init' do
    path '/etc/init.d/gearman-job-server'
    source 'gearmand.init.erb'
    variables(
      :libpq_conninfo => node['gearman-job-server']['libpq']['conninfo']
    )
  end
end
