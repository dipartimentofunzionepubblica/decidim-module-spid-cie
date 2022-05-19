# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    describe Engine do
      # Some of the tests may be causing the Devise OmniAuth strategies to be
      # reconfigured in which case the strategy option information is lost in
      # the Devise configurations. In case the strategy is lost, re-initialize
      # it manually. Normally this is done when the application's middleware
      # stack is loaded.
      after do
        Decidim::Spid.tenants do |tenant|
          name = tenant.name.to_sym
          next if ::Devise.omniauth_configs[name].strategy

          ::OmniAuth::Strategies::Spid.new(
            Rails.application,
            tenant.omniauth_settings
          ) do |strategy|
            ::Devise.omniauth_configs[name].strategy = strategy
          end
        end
      end

      it "mounts the routes to the core engine" do
        routes = double
        allow(Decidim::Core::Engine).to receive(:routes).and_return(routes)
        expect(Decidim::Core::Engine).to receive(:routes)
        expect(routes).to receive(:prepend) do |&block|
          context = double
          expect(context).to receive(:mount).with(described_class => "/")
          context.instance_eval(&block)
        end

        run_initializer("decidim_spid.mount_routes")
      end

      it "adds the correct sign out routes to the core engine" do
        %w(DELETE POST).each do |method|
          expect(
            Decidim::Core::Engine.routes.recognize_path(
              "/users/sign_out",
              method: method
            )
          ).to eq(
            controller: "decidim/spid/sessions",
            action: "destroy"
          )
        end

        expect(
          Decidim::Core::Engine.routes.recognize_path(
            "/users/slo_callback",
            method: "GET"
          )
        ).to eq(
          controller: "decidim/spid/sessions",
          action: "slo_callback"
        )
      end

      it "configures the SPID omniauth strategy for Devise" do
        expect(::Devise).to receive(:setup) do |&block|
          config = double
          expect(config).to receive(:omniauth).with(
            :ciao,
            name: "ciao",
            strategy_class: OmniAuth::Strategies::SpidSaml,
            sp_entity_id: "http://192.168.1.52/",
            sp_name_qualifier: "http://192.168.1.52/",
            idp_slo_session_destroy: instance_of(Proc),
            sp_metadata: {},
            assertion_consumer_service_url: "http://192.168.1.52/users/auth/ciao/callback",
            certificate: ".keys/certificate.pem",
            new_certificate: nil,
            private_key: ".keys/private_key.pem",
            single_logout_service_url: "http://192.168.1.52/users/auth/ciao/slo",
            config: Decidim::Spid.tenants.select { |a| a.name == 'ciao'}.try(:first).config
          )
          block.call(config)
        end
        expect(::Devise).to receive(:setup) do |&block|
          config = double
          expect(config).to receive(:omniauth).with(
            :spid,
            name: "spid",
            strategy_class: OmniAuth::Strategies::SpidSaml,
            sp_entity_id: "http://localhost:3000/",
            sp_name_qualifier: "http://localhost:3000/",
            idp_slo_session_destroy: instance_of(Proc),
            sp_metadata: {},
            assertion_consumer_service_url: "http://localhost:3000/users/auth/spid/callback",
            certificate: ".keys/certificate.pem",
            new_certificate: nil,
            private_key: ".keys/private_key.pem",
            single_logout_service_url: "http://localhost:3000/users/auth/spid/slo",
            config: Decidim::Spid.tenants.select { |a| a.name == 'spid'}.try(:first).config
          )
          block.call(config)
        end

        allow(Decidim::Spid).to receive(:initialized?).and_return(false)
        run_initializer("decidim_spid.setup")
      end

      # it "configures the OmniAuth failure app" do
      #   expect(OmniAuth.config).to receive(:on_failure=) do |proc|
      #     env = double
      #     action = double
      #     expect(env).to receive(:[]).with("PATH_INFO").twice.and_return("/users/auth/ciao")
      #     expect(env).to receive(:[]=).with("devise.mapping", ::Devise.mappings[:user])
      #     allow(Decidim::Spid::OmniauthCallbacksController).to receive(:action).with(:failure).and_return(action)
      #     expect(Decidim::Spid::OmniauthCallbacksController).to receive(:action)
      #     expect(action).to receive(:call).with(env)
      #
      #     proc.call(env)
      #   end
      #
      #   expect(OmniAuth.config).to receive(:on_failure=) do |proc|
      #     env = double
      #     action = double
      #     expect(env).to receive(:[]).with("PATH_INFO").thrice.and_return(
      #       "/users/auth/other"
      #     )
      #     expect(env).to receive(:[]=).with("devise.mapping", ::Devise.mappings[:user])
      #     allow(Decidim::Spid::OmniauthCallbacksController).to receive(
      #       :action
      #     ).with(:failure).and_return(action)
      #     expect(Decidim::Spid::OmniauthCallbacksController).to receive(:action)
      #     expect(action).to receive(:call).with(env)
      #
      #     proc.call(env)
      #   end
      #
      #   allow(Decidim::Spid).to receive(:initialized?).and_return(false)
      #   run_initializer("decidim_spid.setup")
      # end

      it "falls back on the default OmniAuth failure app" do
        failure_app = double

        expect(OmniAuth.config).to receive(:on_failure).twice.and_return(failure_app)
        expect(OmniAuth.config).to receive(:on_failure=).twice do |proc|
          env = double
          expect(env).to receive(:[]).with("PATH_INFO").twice.and_return(
            "/something/else"
          )
          expect(failure_app).to receive(:call).with(env)

          proc.call(env)
        end

        allow(Decidim::Spid).to receive(:initialized?).and_return(false)
        run_initializer("decidim_spid.setup")
      end

      def run_initializer(initializer_name)
        config = described_class.initializers.find do |i|
          i.name == initializer_name
        end
        config.run
      end
    end
  end
end
