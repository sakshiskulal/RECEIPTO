class EmailTemplates {
  static String getWarrantyReminderHtml({
    required String userName,
    required String productName,
    required String merchantName,
    required String purchaseDate,
    required String expiryDate,
    required String daysRemaining,
    required String invoiceNumber,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Warranty Expiration Reminder</title>
  <style>
    body {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: #F3F4F6;
      color: #1F2937;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 20px auto;
      background-color: #FFFFFF;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }
    .header {
      background-color: #1E3A8A;
      color: #FFFFFF;
      padding: 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: 0.5px;
    }
    .header p {
      margin: 4px 0 0 0;
      font-size: 14px;
      opacity: 0.85;
    }
    .content {
      padding: 32px 24px;
    }
    .greeting {
      font-size: 18px;
      font-weight: 600;
      margin-top: 0;
      margin-bottom: 8px;
    }
    .intro {
      font-size: 15px;
      line-height: 1.5;
      color: #4B5563;
      margin-bottom: 24px;
    }
    .card {
      background-color: #EFF6FF;
      border: 1px solid #BFDBFE;
      border-radius: 6px;
      padding: 20px;
      margin-bottom: 24px;
    }
    .card-title {
      font-size: 16px;
      font-weight: 700;
      color: #1E3A8A;
      margin-top: 0;
      margin-bottom: 12px;
    }
    .table {
      width: 100%;
      border-collapse: collapse;
    }
    .table td {
      padding: 8px 0;
      font-size: 14px;
    }
    .table td.label {
      color: #6B7280;
      width: 35%;
      font-weight: 500;
    }
    .table td.value {
      color: #1F2937;
      font-weight: 600;
      text-align: right;
    }
    .table tr.highlight td.value {
      color: #EF4444;
    }
    .footer {
      background-color: #F9FAFB;
      border-top: 1px solid #E5E7EB;
      padding: 20px;
      text-align: center;
      font-size: 12px;
      color: #9CA3AF;
    }
    .footer p {
      margin: 4px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🛡️ Receipto</h1>
      <p>Your Intelligent Warranty Guard</p>
    </div>
    <div class="content">
      <p class="greeting">Hello $userName,</p>
      <p class="intro">This is an automated reminder from Receipto that your product warranty is nearing its expiration. Please find the details below:</p>
      
      <div class="card">
        <div class="card-title">Warranty Protection Summary</div>
        <table class="table">
          <tr>
            <td class="label">Product Name</td>
            <td class="value">$productName</td>
          </tr>
          <tr>
            <td class="label">Merchant</td>
            <td class="value">$merchantName</td>
          </tr>
          <tr>
            <td class="label">Purchase Date</td>
            <td class="value">$purchaseDate</td>
          </tr>
          <tr>
            <td class="label">Expiry Date</td>
            <td class="value">$expiryDate</td>
          </tr>
          <tr class="highlight">
            <td class="label">Days Remaining</td>
            <td class="value">$daysRemaining Days</td>
          </tr>
          <tr>
            <td class="label">Invoice Number</td>
            <td class="value">${invoiceNumber.isNotEmpty ? invoiceNumber : 'N/A'}</td>
          </tr>
        </table>
      </div>
      
      <p class="intro">Please keep your original receipt safe in case you need to file replacement claims or contact customer support.</p>
    </div>
    <div class="footer">
      <p>Thank you for using Receipto,</p>
      <p><strong>The Receipto Team</strong></p>
      <p style="margin-top: 12px; font-size: 11px;">This is a system-generated message. Please do not reply directly to this email.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  static String getTestEmailHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Receipto SMTP Connection Test</title>
  <style>
    body {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: #F3F4F6;
      color: #1F2937;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 20px auto;
      background-color: #FFFFFF;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }
    .header {
      background-color: #1E3A8A;
      color: #FFFFFF;
      padding: 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      font-weight: 700;
    }
    .content {
      padding: 32px 24px;
      text-align: center;
    }
    .success-icon {
      font-size: 48px;
      margin-bottom: 16px;
    }
    .title {
      font-size: 20px;
      font-weight: 700;
      color: #10B981;
      margin-bottom: 12px;
    }
    .message {
      font-size: 15px;
      line-height: 1.6;
      color: #4B5563;
      margin-bottom: 24px;
    }
    .footer {
      background-color: #F9FAFB;
      border-top: 1px solid #E5E7EB;
      padding: 20px;
      font-size: 12px;
      color: #9CA3AF;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🛡️ Receipto</h1>
    </div>
    <div class="content">
      <div class="success-icon">✅</div>
      <div class="title">SMTP Connected Successfully!</div>
      <p class="message">
        Congratulations!<br>
        Your SMTP configuration is working successfully.<br><br>
        This email confirms Receipto can successfully send automated warranty reminder emails.
      </p>
    </div>
    <div class="footer">
      <p>Thank you,</p>
      <p><strong>The Receipto Team</strong></p>
    </div>
  </div>
</body>
</html>
''';
  }
}
