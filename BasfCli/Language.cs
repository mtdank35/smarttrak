﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli
{
    public struct Language
    {
        public const int English = 1;
        public const int French_France = 2;
        public const int Polish = 3;
        public const int French_Canada = 4;
        public const int Spanish_Spain = 5;
        public const int English_UK = 8;
        public const int Italian = 9;
        public const int Dutch = 10;
        public const int Greek = 12;
        public const int Bulgarian = 13;
        public const int Turkish = 14;
        public const int Portuguse = 15;
        public const int German = 17;
        public const int Albanian = 19;
        public const int Slovene = 24;
        public const int Slovak = 25;
        public const int Hungarian = 26;
        public const int Russian = 27;
        public const int Croatian = 28;
        public const int Czech = 29;
        public const int Romainian = 30;
        public const int Norwegian = 31;
        public const int Swedish = 32;
        public const int Danish = 33;
        public const int Estonian = 34;
        public const int Serbian = 35;
        public const int Lithuanian = 38;
        public const int Spanish_LatinAmerica = 39;
        public const int Macedonian = 40;
        public const int Japanese = 41;
        public const int Arabic = 49;
    }

    public class LanguageInfo
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string FileName { get; set; }
    }

    public class LanguageMap
    {
        public Dictionary<int,LanguageInfo> LangMap { get; set; }
        public LanguageMap()
        {
            Init();
        }

        private void Init()
        {
            // Where grabbing filename abbreviations from
            // http://www.sitepoint.com/web-foundations/iso-2-letter-language-codes/
            LangMap = new Dictionary<int, LanguageInfo>();
            LangMap.Add(Language.English, new LanguageInfo() { Id = 1, Name = "English", FileName = "1.en"});
            LangMap.Add(Language.French_France, new LanguageInfo() { Id = 2, Name = "French_France", FileName = "2.fr" });
            LangMap.Add(Language.Polish, new LanguageInfo() { Id = 3, Name = "Polish", FileName = "3.pl" });
            LangMap.Add(Language.French_Canada, new LanguageInfo() { Id = 4, Name = "French_Canada", FileName = "4.fr" });
            LangMap.Add(Language.Spanish_Spain, new LanguageInfo() { Id = 5, Name = "Spanish_Spain", FileName = "5.es" });
            LangMap.Add(Language.English_UK, new LanguageInfo() { Id = 8, Name = "English_UK", FileName = "8.en" });
            LangMap.Add(Language.Italian, new LanguageInfo() { Id = 9, Name = "Italian", FileName = "9.it" });
            LangMap.Add(Language.Dutch, new LanguageInfo() { Id = 10, Name = "Dutch", FileName = "10.nl" });
            LangMap.Add(Language.Greek, new LanguageInfo() { Id = 12, Name = "Greek", FileName = "12.el" });
            LangMap.Add(Language.Bulgarian, new LanguageInfo() { Id = 13, Name = "Bulgarian", FileName = "13.bg" });
            LangMap.Add(Language.Turkish, new LanguageInfo() { Id = 14, Name = "Turkish", FileName = "14.tr" });
            LangMap.Add(Language.Portuguse, new LanguageInfo() { Id = 15, Name = "Portuguse", FileName = "15.pt" });
            LangMap.Add(Language.German, new LanguageInfo() { Id = 17, Name = "German", FileName = "17.de" });
            LangMap.Add(Language.Albanian, new LanguageInfo() { Id = 19, Name = "Albanian", FileName = "19.sq" });
            LangMap.Add(Language.Slovene, new LanguageInfo() { Id = 24, Name = "Slovene", FileName = "24.sl" });
            LangMap.Add(Language.Slovak, new LanguageInfo() { Id = 25, Name = "Slovak", FileName = "25.sk" });
            LangMap.Add(Language.Hungarian, new LanguageInfo() { Id = 26, Name = "Hungarian", FileName = "26.hu" });
            LangMap.Add(Language.Russian, new LanguageInfo() { Id = 27, Name = "Russian", FileName = "27.ru" });
            LangMap.Add(Language.Croatian, new LanguageInfo() { Id = 28, Name = "Croatian", FileName = "28.hr" });
            LangMap.Add(Language.Czech, new LanguageInfo() { Id = 29, Name = "Czech", FileName = "29.cs" });
            LangMap.Add(Language.Romainian, new LanguageInfo() { Id = 30, Name = "Romainian", FileName = "30.ro" });
            LangMap.Add(Language.Norwegian, new LanguageInfo() { Id = 31, Name = "Norwegian", FileName = "31.no" });
            LangMap.Add(Language.Swedish, new LanguageInfo() { Id = 32, Name = "Swedish", FileName = "32.sv" });
            LangMap.Add(Language.Danish, new LanguageInfo() { Id = 33, Name = "Danish", FileName = "33.da" });
            LangMap.Add(Language.Estonian, new LanguageInfo() { Id = 34, Name = "Estonian", FileName = "34.et" });
            LangMap.Add(Language.Serbian, new LanguageInfo() { Id = 35, Name = "Serbian", FileName = "35.sr" });
            LangMap.Add(Language.Lithuanian, new LanguageInfo() { Id = 38, Name = "Lithuanian", FileName = "38.lt" });
            LangMap.Add(Language.Spanish_LatinAmerica, new LanguageInfo() { Id = 39, Name = "Spanish_LatinAmerica", FileName = "39.es" });
            LangMap.Add(Language.Macedonian, new LanguageInfo() { Id = 40, Name = "Macedonian", FileName = "40.mk" });
            LangMap.Add(Language.Japanese, new LanguageInfo() { Id = 41, Name = "Japanese", FileName = "41.ja" });
            LangMap.Add(Language.Arabic, new LanguageInfo() { Id = 49, Name = "Arabic", FileName = "49.ar" });
        }
    }
}
