describe "Chef::Provisioning::Dummy" do
  extend DummySupport
  include DummyConfig

  when_the_chef_12_server "exists", server_scope: :context, port: 8900..9000 do
    with_dummy "integration tests" do
      context "machine resource" do
        it "runs :create by default" do
          expect_recipe {
            machine "fake-machine"
          }
        end
      end
    end
  end
end
