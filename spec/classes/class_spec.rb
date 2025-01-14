require 'spec_helper'

shared_examples_for "base case" do
  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_class('autosign::params') }
  it { is_expected.to contain_class('autosign::install').that_comes_before('Class[autosign::config]') }
  it { is_expected.to contain_class('autosign::config') }
end

describe 'autosign' do
  context "autosign class without any parameters" do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:params) {{ }}

        it_behaves_like "base case"
        it { is_expected.to contain_package('autosign').with_ensure('present') }
      end
    end
  end

  context "autosign class with some parameters" do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:params) {{
          :ensure => 'latest',
          :config => { 'jwt_token' => { 'secret' => 'hunter2' } },
          }}
        if ['FreeBSD', 'OpenBSD'].include?(os_facts[:osfamily])
          base_configpath = '/usr/local/etc'
          base_journalpath = '/var/autosign'
        else
          base_configpath = '/etc'
          base_journalpath = '/var/lib/autosign'
        end

        it_behaves_like "base case"

        it { is_expected.to contain_package('autosign').with_ensure('latest') }
        it { is_expected.to contain_file("#{base_configpath}/autosign.conf").with_ensure('file') }
        it { is_expected.to contain_file("#{base_journalpath}/autosign.journal").with_ensure('file') }
        it { is_expected.to contain_file('/var/log/autosign.log').with_ensure('file') }
        it { is_expected.to contain_file(base_journalpath) }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'autosign class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
        }}

      it { expect { is_expected.to contain_package('autosign') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end

  context "when running Puppet Enterprise" do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts.merge({
          :pe_server_version => '2017.3.2',
          }) }
        let(:params) {{ }}

        it_behaves_like "base case"
        it { is_expected.to contain_package('autosign').with_ensure('present') }
        it { is_expected.to contain_file('/var/log/puppetlabs/puppetserver/autosign.log').with_ensure('file') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppetserver/autosign.conf').with_ensure('file') }
        it { is_expected.to contain_file('/opt/puppetlabs/server/autosign/autosign.journal').with_ensure('file') }
        it { is_expected.to contain_file('/opt/puppetlabs/server/autosign').with_ensure('directory') }
      end
    end
  end

  context "when overriding options" do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:params) {{
          :ensure             => '0.1.0',
          :configfile         => '/etc/autosign1.conf',
          :manage_journalfile => false,
          :manage_logfile     => false,
        }}

        it_behaves_like "base case"
        it { is_expected.to contain_package('autosign').with_ensure('0.1.0') }
        it { is_expected.to contain_file('/etc/autosign1.conf').with_ensure('file') }
        it { is_expected.not_to contain_file('/var/lib/autosign/autosign.journal')}
        it { is_expected.not_to contain_file('/var/log/autosign.log')}
        it { is_expected.not_to contain_file('/var/lib/autosign') }
      end
    end
  end
end
