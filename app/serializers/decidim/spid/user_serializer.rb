# frozen_string_literal: true

module Decidim
  module Spid
    # This class serializes an Assembly so it can be exported to CSV, JSON or other formats.
    class UserSerializer < Decidim::Exporters::Serializer
      include Decidim::ApplicationHelper
      include Decidim::ResourceHelper
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a user.
      def initialize(user)
        @user = user
      end

      # Public: Exports a hash with the serialized data for this user.
      def serialize
        {
          id: user.id,
          email: user.email,
          name: user.name,
          nickname: user.nickname,
          locale: user.locale,
          organization: {
            id: user.organization.try(:id),
            name: user.organization.try(:name)
          },
          newsletter_notifications_at: user.newsletter_notifications_at,
          email_on_notification: user.email_on_notification,
          admin: user.admin,
          personal_url: user.personal_url,
          about: user.about,
          invitation_created_at: user.invitation_created_at,
          invitation_sent_at: user.invitation_sent_at,
          invitation_accepted_at: user.invitation_accepted_at,
          invited_by: {
            id: user.invited_by_id,
            type: user.invited_by_type
          },
          invitations_count: user.invitations_count,
          reset_password_sent_at: user.reset_password_sent_at,
          remember_created_at: user.remember_created_at,
          sign_in_count: user.sign_in_count,
          current_sign_in_at: user.current_sign_in_at,
          last_sign_in_at: user.last_sign_in_at,
          current_sign_in_ip: user.current_sign_in_ip,
          last_sign_in_ip: user.last_sign_in_ip,
          created_at: user.created_at,
          updated_at: user.updated_at,
          confirmed_at: user.confirmed_at,
          confirmation_sent_at: user.confirmation_sent_at,
          unconfirmed_email: user.unconfirmed_email,
          delete_reason: user.delete_reason,
          deleted_at: user.deleted_at,
          managed: user.managed,
          officialized_at: user.officialized_at,
          officialized_as: user.officialized_as,
          identities: serialize_identities,
          spid: serialize_metadata
        }
      end

      private

      attr_reader :user

      def serialize_metadata
        tenant_name = user.organization.enabled_omniauth_providers.dig(:spid, :tenant_name)
        tenant = Decidim::Spid.tenants.find { |t| t.name == tenant_name }
        return {} if tenant.blank?

        auth = Decidim::Authorization.find_by(decidim_user_id: user.id, name: "#{tenant_name}_identity")
        return {} unless auth.present?

        excluded_attributes = tenant.export_exclude_attributes.map(&:to_sym)
        return {} if excluded_attributes.blank?

        results = {}
        auth.metadata.keys.each do |k|
          next if tenant.export_exclude_attributes.include?(k.to_sym)
          results[k] = auth.metadata[k]
        end

        results
      end

      def serialize_identities
        return unless user.identities.any?

        user.identities.map do |identity|
          {
            id: identity.try(:id),
            provider: identity.try(:provider),
            uid: identity.try(:uid),
          }
        end
      end

    end
  end
end
