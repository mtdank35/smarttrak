using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Reflection;
using DapperExtensions;
using DapperExtensions.Mapper;
using DapperExtensions.Sql;
using Basf.Data.Repos;

namespace Basf.Data
{
    public class DataDbi : IDisposable
    {
        private SqlConnection _cn = null;
        public SqlConnection Cn
        {
            get
            {
                return _cn;
            }
        }
        private IDatabase _db = null;

        // IDisposable members and destructor
        private bool disposed = false;
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
        private void Dispose(bool disposing)
        {
            if (!this.disposed)
            {
                if (disposing)
                {
                    if (_cn != null)
                        _cn.Dispose();
                    if (_db != null)
                        _db.Dispose();
                }
                disposed = true;
            }
        }
        ~DataDbi()
        {
            Dispose(false);
        }

        public DataDbi(string dbcs)
        {
            // make Dapper use ANSI strings (faster than Unicode)
            //Dapper.SqlMapper.AddTypeMap(typeof(string), System.Data.DbType.AnsiString);

            _cn = new SqlConnection(dbcs);
            var config = new DapperExtensionsConfiguration(typeof(AutoClassMapper<>), new List<Assembly>(), new SqlServerDialect());
            var sqlGenerator = new SqlGeneratorImpl(config);
            _db = new Database(_cn, sqlGenerator);

            SetupRepos();
        }

        private void SetupRepos()
        {
            _pntLineRepo = new PntLineRepo(_db);
        }


        private PntLineRepo _pntLineRepo = null;
        public PntLineRepo PntLine
        {
            get
            {
                return _pntLineRepo;
            }
        }

    }
}
