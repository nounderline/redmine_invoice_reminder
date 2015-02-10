Redmine::Plugin.register :redmine_invoice_reminder do
  name 'Redmine Invoice Reminder plugin'
  author 'Ralph Gutkowski'
  description 'Remind contacts about overdue invoice'
  version '0.0.2'
  url 'http://rgtos.com'
  author_url 'http://rgtos.com'

  settings :default => {
    :invoice_reminder_email_subject => '',
    :invoice_reminder_email_body => '',
    :invoice_reminder_email_from => '<Jack Stuntman> jack@example.com',
    :invoice_reminder_email_pdf_attachment => '1',
    :invoice_reminder_email_recipients => []
  }, :partial => 'settings/redmine_invoice_reminder/redmine_invoice_reminder'

  requires_redmine_plugin :redmine_contacts,          :version_or_higher => '3.4.0'
  requires_redmine_plugin :redmine_contacts_invoices, :version_or_higher => '3.2.0'
end