using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace SlackChannelPost.Configuration
{
	public class ConfContainer
	{
		public ConfContainer(string dir)
		{
			_dbConf = LoadConf<DbConf>(dir, "db.conf");
			_smtpConf = LoadConf<SmtpConf>(dir, "smtp.conf");
			_slackApiConf = LoadConf<SlackApiConf>(dir, "slackapi.conf");

		}

		private T LoadConf<T>(string dir, string filename)
		{
			string confFile = Path.Combine(dir, filename);
			if (File.Exists(confFile))
			{
				// load existing conf file
				string json = File.ReadAllText(confFile);
				var existConf = Newtonsoft.Json.JsonConvert.DeserializeObject<T>(json);
				return existConf;
			}
			else
			{
				// save a fresh conf file if none found
				var newConf = (T)Activator.CreateInstance(typeof(T));
				File.WriteAllText(confFile, JsonConvert.SerializeObject(newConf));
				return newConf;
			}
		}

		private DbConf _dbConf;
		public DbConf Db
		{
			get
			{
				return _dbConf;
			}
		}

		private SmtpConf _smtpConf;
		public SmtpConf Smtp
		{
			get
			{
				return _smtpConf;
			}
		}

		private SlackApiConf _slackApiConf;
		public SlackApiConf SlackApi
		{
			get
			{
				return _slackApiConf;
			}
		}
	}
}
