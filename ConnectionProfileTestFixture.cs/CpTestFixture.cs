using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConnectionProfiles.Tests
{
    public class CpTestFixture
    {
        public CpTestFixture()
        {}

        [SetUp]
        public void Setup()
        {}

        [Test]
        public void PwdSerTest1()
        {
            // Generic pwd
            var pwd = "ThisIsMyStrongPwd";
            
            // Serialized
            var serPwd = Convert.ToBase64String(Encoding.UTF8.GetBytes(pwd));
            Assert.AreNotEqual(pwd, serPwd);

            // Deseralized
            byte[] bytes = Convert.FromBase64String(serPwd);
            var dSerPwd = Encoding.UTF8.GetString(bytes);

            // make sure it comes back to origin
            Assert.AreEqual(pwd, dSerPwd);
        }

        [Test]
        public void PwdSerTest2()
        {
            // Generic pwd
            var pwd = "Here1sAn0ther!Strong0ne";

            // Serialized
            var serPwd = Convert.ToBase64String(Encoding.UTF8.GetBytes(pwd));
            Assert.AreNotEqual(pwd, serPwd);

            // Deseralized
            byte[] bytes = Convert.FromBase64String(serPwd);
            var dSerPwd = Encoding.UTF8.GetString(bytes);

            // make sure it comes back to origin
            Assert.AreEqual(pwd, dSerPwd);
        }

        [Test]
        public void DbcsSer1()
        {
            // Generic pwd
            var pwd = "Here1sAn0ther!Strong0ne";

            // Serialized
            var serPwd = Convert.ToBase64String(Encoding.UTF8.GetBytes(pwd));
            Assert.AreNotEqual(pwd, serPwd);

            var dbcs = "Data Source=.\\SQL_ICCM;Initial Catalog=CustDataNA;Integrated Security=False;User ID=sa;Password=InsertPwdHere;Connect Timeout=5";
            var scb = new SqlConnectionStringBuilder(dbcs);
            Assert.AreEqual("InsertPwdHere", scb.Password);
            scb.Password = serPwd;

            // replace the serialized pwd in the connect string
            var serDbcs = String.Format("Data Source=.\\SQL_ICCM;Initial Catalog=CustDataNA;Integrated Security=False;User ID=sa;Password=\"{0}\";Connect Timeout=5", serPwd);
            Assert.AreEqual(scb.ConnectionString, serDbcs);
            System.Diagnostics.Debug.WriteLine("Encoded DBCS:  {0}", scb.ConnectionString);
        }
    }
}
