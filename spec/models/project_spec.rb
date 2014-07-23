require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Project do

  before(:all) do
    @project    = FactoryGirl.create(:project)

    @git_repo_1 = FactoryGirl.create(:repository_git, :project_id => @project.id, :is_default => true)
    @git_repo_2 = FactoryGirl.create(:repository_git, :project_id => @project.id, :identifier => 'git-repo-test')

    @svn_repo_1 = FactoryGirl.create(:repository_svn, :project_id => @project.id, :identifier => 'svn-repo-test', :url => 'http://svn-repo-test')
  end

  subject { @project }

  ## Test relations
  it { should respond_to(:gitolite_repos) }
  it { should respond_to(:repo_blank_ident) }

  it "should have 1 repository with blank ident" do
    expect(@project.repo_blank_ident).to eq @git_repo_1
  end

  it "should have 2 Git repositories" do
    expect(@project.gitolite_repos).to eq [@git_repo_1, @git_repo_2]
  end

  it "should not match existing repository identifier" do
    expect(FactoryGirl.build(:project, :identifier => 'git-repo-test')).to be_invalid
  end

  it "should not match Gitolite Admin repository identifier" do
    expect(FactoryGirl.build(:project, :identifier => 'gitolite-admin')).to be_invalid
  end

end