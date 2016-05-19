using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli.Conf
{
    public class ConfContainer
    {
        private const string GLOBAL_CONF_FILENAME = "global.conf";
        private const string AWSS3_CONF_FILENAME = "awsS3.conf";
        private string _dir;

        public ConfContainer(string dir)
        {
            _dir = dir;
            _globalConf = LoadConf<GlobalConf>(_dir, GLOBAL_CONF_FILENAME);
            _awsS3Conf = LoadConf<AwsS3Conf>(_dir, AWSS3_CONF_FILENAME);
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

        // global conf
        private GlobalConf _globalConf;
        public GlobalConf Global
        {
            get
            {
                return _globalConf;
            }
        }

        private AwsS3Conf _awsS3Conf;
        public AwsS3Conf AwsS3
        {
            get
            {
                return _awsS3Conf;
            }
        }
    }
}
