using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SlackChannelPost.Configuration
{
	public class SmtpConf
	{
		public string Server { get; set; }
		public int Port { get; set; }
		public bool EnableSsl { get; set; }
		public string User { get; set; }
		public string Password { get; set; }
		public string ReplyTo { get; set; }

		public SmtpConf()
		{
			Server = "smtp.localhost.com";
			Port = 587;
			EnableSsl = true;
			User = "mailer1@localhost.com";
			Password = "123";
			ReplyTo = "errors@localhost.com";
		}
	}
}
