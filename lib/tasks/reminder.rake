desc <<-END_DESC
Send reminders about overdue invoices.
END_DESC

namespace :redmine_invoice_reminder do
  # TODO: use raw SQL for better performance with support
  #       for multiple SQL dialects (sqlite, mysql, postgresql)
  task :send_reminders => :environment do
    now = Date.today
    invoices = Invoice.where(:status_id => Invoice::SENT_INVOICE).where("due_date IS NOT NULL")

    invoices.each do |invoice|

      due = invoice.due_date.to_date

      if due.today? or (due === 3.days.ago.to_date) \
         or (due > now && (due - now).to_i.even?)
         msg = InvoiceReminderMailer.invoice_reminder(invoice)
         mails = msg.bcc.dup
         mails.push(msg.to) if msg.to.present?
         
         msg.deliver
         puts "Invoice##{invoice.id} reminder sent to #{mails.join(', ')}"
      end
    end
  end
end
