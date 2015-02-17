module InvoiceReminderHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper
  include InvoicesHelper

  def format_invoice_reminder
    settings = Setting.plugin_redmine_invoice_reminder
    args = {
      :'invoice.url' => url_for(@invoice),
      :'invoice.number' => @invoice.number,
      :'invoice.issue_date' => @invoice.invoice_date.to_date,
      :'invoice.due_date' => @invoice.due_date.to_date,
      :'invoice.total' => number_to_currency(@invoice.amount,
                                  :unit => @invoice.currency, :format => "%n %u",
                                  :separator => ',', :delimiter => ' '),
      :'project.name' => @project.name
    }

    return {
      :subject => (settings[:invoice_reminder_email_subject] % args),
      :body => (settings[:invoice_reminder_email_body] % args)
    }
  end
 
  # Get all object from database defined in plugin settings
  def recipient_objects
    recipients = []
    @members = @project.member_principals
    settings = Setting.plugin_redmine_invoice_reminder
    codes = settings[:invoice_reminder_email_recipients]
    user_ids, role_ids = [], []

    codes.each do |code|
      splitted = code.split('_')
      type, value = splitted[0], splitted[1]

      case type
        when 'u'
          user_ids << value.to_i
        when 'r'
          role_ids << value.to_i
        when ''
          recipients << @invoice.contact if @invoice.contact and value == 'contact' 
      end
    end

    if user_ids.present?
      User.find(user_ids).each do |user|
        recipients << user
      end
    end

    if role_ids.present?
      role_ids.each do |r_id|
        @members.each { |m|
          user = m.user
          m_role_ids = m.roles.pluck(:id)
          if m_role_ids.include? r_id
            recipients << user 
          end
        }
      end
   end

    recipients.uniq
  end

  # From objects defined in settings fetch e-mail adressed formated
  # as "name <email@example.com"
  def invoice_email_tos
    tos = []

    recipient_objects.each do |recipient|
      case recipient
        when User
          user = recipient
          user.name = '' if !user.name
          if user.mail.present? and user_in_members? user
            tos << "#{user.name} <#{user.mail}>" 
          end
        when Contact
          contact = recipient
          tos << "#{contact.name} <#{contact.email}>" if not contact.email.empty?
      end
    end

    tos.uniq
  end

  def user_in_members?(user)
    !!@members.find { |member| member.user_id == user.id } 
  end

  def project_user_roles
    Member.includes(:user, :roles).where(project_id: @project.id)
  end
end
