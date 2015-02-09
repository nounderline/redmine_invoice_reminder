module InvoiceReminderHelper
  include ActionView::Helpers::NumberHelper

  def format_invoice_reminder_body(invoice, body)
    args = {}
    args[:'invoice.number'] = invoice.number.to_s
    args[:'invoice.issue_date'] = invoice.invoice_date.to_date
    args[:'invoice.due_date'] = invoice.due_date.to_date
    args[:'invoice.total'] = number_to_currency invoice.amount, :unit => invoice.currency, :format => "%n %u",
                                                                :separator => ',', :delimiter => ' '
    body % args
  end
end