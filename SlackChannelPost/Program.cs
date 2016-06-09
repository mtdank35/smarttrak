using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.IO;
using SlackChannelPost.Configuration;
using Dapper;
using DapperExtensions;
using Newtonsoft.Json;
using RestSharp;

namespace SlackChannelPost
{
	class Program
	{
		private static ConfContainer _conf;
		static void Main(string[] args)
		{
			Console.Out.WriteLine("<starting>");

			JsonConvert.DefaultSettings = (() =>
			{
				var settings = new JsonSerializerSettings();
				settings.Formatting = Formatting.Indented;											// pretty json
				settings.Converters.Add(new Newtonsoft.Json.Converters.StringEnumConverter());      // save enums as strings, not ints
				settings.DateFormatHandling = DateFormatHandling.IsoDateFormat;						// 2012-03-21T05:40Z
				return settings;
			});
			var ea = System.Reflection.Assembly.GetEntryAssembly();
			FileInfo fi = new FileInfo(ea.Location);
			_conf = new ConfContainer(fi.Directory.FullName);
			WaitForSqlServer();
			try
			{
				DoThings();
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
			}
			finally
			{
				Console.Out.WriteLine("<exiting>");
			}
		}

		private static void DoThings()
		{
			Console.Out.WriteLine("checking queue...");
			// query db for messages to send
			using (SqlConnection cn = new SqlConnection(_conf.Db.Dbcs))
			{
				cn.Open();
				var count = AlertMsgRepo.GetUnsentCount(cn);
				if (count == 0)
				{
					Console.Out.WriteLine("no messages queued");
					return;
				}

				// FUTURE: avoid duplicates
				var unsentMsgList = AlertMsgRepo.GetUnsent(cn);
				foreach (var unsentMsg in unsentMsgList)
				{
					List<AlertMsgTarget> msgTargets;
					Crash c;
					CrashInstance ci;
					Customer cust;
					string sql = @"
SELECT 
	ar.RuleName
	,at.*
FROM AlertRule ar 
INNER JOIN AlertRuleTarget art ON
	art.RuleId = ar.RuleId
	AND art.IsEnabled = 1
INNER JOIN AlertTarget at ON
	at.TargetId = art.TargetId
WHERE ar.RuleId = @p1

SELECT * FROM Crash WHERE CrashId = @p2
SELECT * FROM CrashInstance WHERE InstanceId = @p3
SELECT c.* FROM Customer c INNER JOIN CrashInstance ci ON ci.InstanceId = @p3 AND ci.CustId = c.CustId
";
					using (var multi = cn.QueryMultiple(sql, new { p1 = unsentMsg.RuleId, p2 = unsentMsg.CrashId, p3 = unsentMsg.InstanceId }))
					{
						msgTargets = multi.Read<AlertMsgTarget>().ToList();
						c = multi.Read<Crash>().Single();
						ci = multi.Read<CrashInstance>().Single();
						cust = multi.Read<Customer>().Single();
					}

					// find all email targets and send 1 email msg
					var emailTgtAddrList = msgTargets.Where(x => x.TargetType == 1).Select(y => y.TargetAddr).Distinct().ToList();
					if (emailTgtAddrList.Count > 0)
					{
						var msgBody = new StringBuilder();
						msgBody.AppendLine(String.Format("Crash:  http://ctsops.azurewebsites.net/Home/Instances?crashId={0:g}", unsentMsg.CrashId));
						msgBody.AppendLine(String.Format("Instance:  http://ctsops.azurewebsites.net/Home/InstanceDetail/{0:g0}", unsentMsg.InstanceId));
						msgBody.AppendLine("");
						msgBody.AppendLine(String.Format("CustName: {0}", cust.CustName));
						msgBody.AppendLine(String.Format("CustGroup: {0}", cust.CustGroup));
						msgBody.AppendLine(String.Format("SiteId: {0}", cust.SiteId));
						msgBody.AppendLine(String.Format("SiteType: {0}", cust.SiteType));
						msgBody.AppendLine(String.Format("AppName: {0}", c.AppName));
						msgBody.AppendLine(String.Format("AppVer: {0}", c.AppVer));
						msgBody.AppendLine("");
						msgBody.AppendLine(ci.Json);
						msgBody.AppendLine("");
						SendEmailMsg(c.ExMsg, msgBody, emailTgtAddrList);
					}

					// find all non-email targets
					var otherAlertMsgTargets = msgTargets.Where(x => x.TargetType != 1).ToList();
					if (otherAlertMsgTargets.Count > 0)
					{
						foreach (var target in otherAlertMsgTargets)
						{
							switch (target.TargetType)
							{
								case 2: // SLACK API
									SendSlackAlert(target, c, ci, cust);
									break;
									// FUTURE: SMS
								default:
									Console.Out.WriteLine("unsupported target types ignored");
									break;
							}
						}
					}
					
					// mark each as sent
					AlertMsgRepo.SetSent(cn, unsentMsg.MsgId);
				}
			}
		}

		private static void SendSlackAlert(AlertMsgTarget target, Crash c, CrashInstance ci, Customer cust)
		{
			try
			{
				var client = new RestClient(_conf.SlackApi.Url);
				var req = new RestRequest();
				req.RequestFormat = DataFormat.Json;
				req.Parameters.Add(new Parameter() { Name = "token", Value = _conf.SlackApi.Token, ContentType = "application/json", Type = ParameterType.GetOrPost });
				req.Parameters.Add(new Parameter() { Name = "channel", Value = String.IsNullOrEmpty(target.TargetAddr) ? _conf.SlackApi.Channel : target.TargetAddr, ContentType = "application/json", Type = ParameterType.GetOrPost });
				req.Parameters.Add(new Parameter() { Name = "username", Value = _conf.SlackApi.BotName, ContentType = "application/json", Type = ParameterType.GetOrPost });
				//req.Parameters.Add(new Parameter() { Name = "text", Value = "", ContentType = "application/json", Type = ParameterType.GetOrPost });
				req.Parameters.Add(new Parameter() { Name = "icon_emoji", Value = _conf.SlackApi.IconEmoji, ContentType = "application/json", Type = ParameterType.GetOrPost });

				var cLink = String.Format("http://ctsops.azurewebsites.net/Home/Instances?crashId={0:g}", ci.CrashId);
				var ciLink = String.Format("http://ctsops.azurewebsites.net/Home/InstanceDetail/{0:g}", ci.InstanceId);
				var attachment = new StructuredMsgAttachment();
				attachment.fallback = String.Format("Crash Instance #{0:g}: {1} - {2}", ci.InstanceId, c.ExMsg, ciLink);
				attachment.pretext = String.Format("From {1} {0}-{2}", cust.SiteId, cust.SiteType, cust.CustName);
				attachment.title = String.Format("Crash Instance #{0:g}: {1}", ci.InstanceId, c.ExMsg);
				attachment.title_link = ciLink;
                attachment.text = String.Format("{0}(v{1}) [Type: {2}; Src: {3}]", c.AppName, c.AppVer, c.ExType, c.ExSource);
				attachment.color = "#7CD197";
				var attachments = new List<StructuredMsgAttachment>() { attachment };
				req.Parameters.Add(new Parameter() { Name = "attachments", Value = GetJson(attachments.ToArray()), ContentType = "application/json", Type = ParameterType.GetOrPost });
				var response = client.Post(req);
				if (response.StatusCode != System.Net.HttpStatusCode.OK)
				{
					Console.Out.WriteLine(String.Format("Failure posting chat message {0}", response.Content));
				}
				else
				{
					// check success response for failure
					var content = JsonConvert.DeserializeObject<SlackResponseContent>(response.Content);
					if (!content.ok)
						Console.Out.WriteLine(String.Format("Failure posting chat message: {0}", content.error));
				}
			}
			catch (Exception ex)
			{
				Console.Out.WriteLine(String.Format("Failure posting chat message {0}", ex.Message));
			}
		}

		private static string GetJson(object thing)
		{
			JsonSerializerSettings jsSettings = new JsonSerializerSettings()
			{
				NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore,
				DateFormatHandling = DateFormatHandling.IsoDateFormat,
				DateTimeZoneHandling = DateTimeZoneHandling.Local,
				Formatting = Formatting.Indented,
				ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
			};
			jsSettings.Converters.Add(new Newtonsoft.Json.Converters.StringEnumConverter());
			return JsonConvert.SerializeObject(thing, jsSettings);
		}

		private static void WaitForSqlServer()
		{
			DateTime firstCheckTime = DateTime.Now;
			int attempts = 0;
			using (SqlConnection cn = new SqlConnection(_conf.Db.Dbcs))
			{
				DateTime nextNotifyTime = new DateTime(1900, 1, 1);
				DateTime nextCheckTime = DateTime.Now;
				bool cnWasDown = false;
				while (true)
				{
					try
					{
						while (DateTime.Now < nextCheckTime)
							Thread.Sleep(1000);
						attempts++;
						cn.Open();
						cn.Close();
						if (attempts > 1 && cnWasDown)
						{
							TimeSpan tspan = DateTime.Now.Subtract(firstCheckTime);
							Console.Out.WriteLine(String.Format("sqlserver up after downtime of {0:00} hours, {1:00} minutes, {2:00} seconds", tspan.Hours, tspan.Minutes, tspan.Seconds));
						}
						return;
					}
					catch (Exception ex)
					{
						cnWasDown = true;
						Console.Error.WriteLine(ex);
						if (DateTime.Now > nextNotifyTime)
						{
							TimeSpan tspan = DateTime.Now.Subtract(firstCheckTime);
							string msg = String.Format("sqlserver down since {0} (elapsed {1:00}:{2:00}:{3:00})", firstCheckTime, tspan.Hours, tspan.Minutes, tspan.Seconds);
							Console.Out.WriteLine(msg);
							nextNotifyTime = DateTime.Now.AddMinutes(15);
						}
						nextCheckTime = DateTime.Now.AddSeconds(5);
					}
				}
			}
		}

		private static void SendEmailMsg(string mailSubject, StringBuilder mailBody, List<string> addrList)
		{
			MailMessage mailMsg = new MailMessage();
			mailMsg.From = new MailAddress(_conf.Smtp.ReplyTo);
			foreach (var recipient in addrList)
				mailMsg.To.Add(recipient);

			mailMsg.Body = mailBody.ToString();

			try
			{
				mailMsg.Subject = ScrubEmailSubject(mailSubject);
			}
			catch (System.ArgumentException argEx)
			{
				//FIND OUT WHY ScrubEmailSubject() didn't return something that will function as an System.Net.Mail.MailMessage.Subject
				Console.Error.WriteLine("BAD EMAIL SUBJECT", argEx);
				mailMsg.Subject = "SmartGrocer Exception (no subject)";
			}

			try
			{
				using (SmtpClient smtp = new SmtpClient(_conf.Smtp.Server, _conf.Smtp.Port))
				{
					smtp.EnableSsl = _conf.Smtp.EnableSsl;
					smtp.UseDefaultCredentials = false;
					smtp.Credentials = new System.Net.NetworkCredential(_conf.Smtp.User, _conf.Smtp.Password);
					Console.Out.WriteLine("logging in as '{0}'", _conf.Smtp.User);
					Console.Out.WriteLine("   send to '{0}' -- '{1}'", String.Join(",", addrList), mailSubject);
					smtp.Send(mailMsg);
				}
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
			}
		}

		private static string ScrubEmailSubject(string mailSubject)
		{
			string subject = mailSubject
				.Replace(Environment.NewLine, String.Empty)
				.Replace("\n", String.Empty)
				.Replace("\r", String.Empty);

			return subject;
		}
	}
}
