describe Fastlane::Actions::GithubApiAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The github_api plugin is working!")

      Fastlane::Actions::GithubApiAction.run(nil)
    end
  end
end
