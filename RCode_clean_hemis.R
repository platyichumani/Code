setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(tidyverse)
library(readxl)
library(cli)
library(data.table)
library(eeptools)
library(utf8)

xlfile <- list.files(pattern = "xlsx")

txtfile <- list.files(pattern = "txt")

resdat <- read_delim(txtfile[7], delim = "\t") %>% 
  rename_with(.fn = toupper) %>% 
  select(-c(FLOOR, ROOM, EXIT_CODE, CAMPUS_CODE,
            RESIDENCE, SURNAME, FIRST_NAMES)) %>% 
  mutate(IDEN = hash_sha256(STUDENT)) %>% 
  relocate(IDEN) %>% 
  select(-STUDENT)

enrdat <- read_excel("0_2015-2022_Enrolments.xlsx",
                     skip = 2L) %>% 
  rename_with(.fn = toupper) %>% 
  select(-c(`STUDENT NAME`, `FIRST NAMES`, `SURNAME`, TITLE,
            `FACULTY SCHOOL`, `DEPT CODE`, 
            `CITIZENSHIP CODE`, `QUALIFICATION TYPE CODE`,
            `CAMPUS CODE`, `ALIEN INDICATOR`, `PREVIOUS ACTIVITY`,
            `ID NUMBER`, `COUNTRY CODE`, `PASSPORT NUMBER`, `SECONDARY SCHOOL`,
            `CREATED BY WEB`)) %>%
  mutate(IDEN = hash_sha256(`STUDENT NUMBER`),
         BIRTHDATE = as.Date(BIRTHDATE, origin = "1899-12-30"),
         `TRANSACTION DATE` = as.Date(`TRANSACTION DATE`, origin = "1899-12-30"),
         AGE_AT_REG = age_calc(dob = BIRTHDATE,
                                         enddate = `TRANSACTION DATE`,
                                         units = "years") %>% round(digits = 1)) %>% 
  relocate(IDEN) %>% 
  select(-c(`STUDENT NUMBER`, BIRTHDATE)) %>% 
  mutate(`SECONDARY SCHOOL NAME` = gsub(pattern = "KWA-ZULU|KWAZULA NATAL|KWAZULU  NATAL|- KZN|KWAZULU NATAL|KWA ZULU NATAL|KWAZULU - NATAL|KEAZULU NATAL|DURBAN|MOBENI|Pietermaritzburg",
                                                 replacement = "KWAZULU-NATAL", x = `SECONDARY SCHOOL NAME`) %>% 
                                gsub(pattern = "FREESTATE", replacement = "FREE STATE") %>% 
                                gsub(pattern = "NORTHEN CAPE|- NC\\)|NORTH CAPE", replacement = "NORTHERN CAPE") %>% 
                                gsub(pattern = "NORTH-WEST|RUSTENBURG", replacement = "NORTH WEST") %>% 
                                gsub(pattern = "-EC|- EC\\)|\\(EC\\)|UITENHAGE|PORT ELIZABETH|UMTATA", replacement = "EASTERN CAPE") %>% 
                                gsub(pattern = "NORTHERN PROVINCE", replacement = "LIMPOPO") %>% 
                                gsub(pattern = "\\(WC\\)|CAPE TOWN", replacement = "WESTERN CAPE"))

provnames9 <- c("EASTERN CAPE", "WESTERN CAPE", "NORTHERN CAPE", 
                "GAUTENG", "MPUMALANGA", "LIMPOPO", "KWAZULU-NATAL",
                "FREE STATE", "NORTH WEST")

provnames <- c("EASTERN CAPE", "WESTERN CAPE", "NORTHERN CAPE", 
               "GAUTENG", "MPUMALANGA", "LIMPOPO", "KWAZULU-NATAL",
               "FREE STATE", "NORTH WEST", "NORTHERN PROVINCE", 
               "EASTERN CAP", 
               "ATLANTIS", 
               "GUGULETU COMPREHENSIVE", "KWAZULU - NATAL",
               "STELLENBOSCH", "- EC\\)", "\\(LANGA\\)", "MANZOMTHOMBO",
               "THEMBALETHU HIGH SCHOOL", "MARIAZELL", "KING COMMERCIAL",
               "BREERIVIER SENIOR", "NOMAKA MBEKI",  
               "E/CAPE", "EASTERN CA", "KWAZULA NATAL", "JOHANNESBURG",
               "KASSELSVLEI", "- WEST COAST", "FALSE BAY", "BHEKUZULU HIGH SCHOOL",
               "ST FRANCIS ADULT", "NGCINGWANE TECHNICAL", "NORTHLINK",
               "DESMUND TUTU", "INKWENKWEZI", "COLLEGE-BISHO", "IINGCINGA ZETHU",
               "VISTA NOVASKOOL", "SAKHISIZWE", "KING SABATA DALINDYEBO", "ST MARTIN",
               "- MAJUBA", "KWAFICA", "KNOWTECH HIGH", "HARRISMITH",
               "SITHEMBELE MATISO", "TRANSKEI", "JONQILIZWE", "TSHWANE", "BELLVILLE",
               "STRAND HS", "DANIELSKUIL HIGH SCHOOL", "POINT HIGH SCHOOL",
               "BELVILLE", "SPRINGBOK", "EAST LONDON", "MASCCOM TRAINING CENTRE",
               "DR VILJOEN C/S", "KHWEZI LOMSO SEC SCHOOL", "BATANDWA NDONDO SSS",
               "ATHLONE SCHOOL FOR THE BLIND", "MOLOKE COMBINED SCHOOL",
               "MIDRAND PARALLEL MEDIUM HIGH", "KENHARDT HIGH SCHOOL", 
               "DIVINE MASTER\\'S ACADEMY", "DANVILLE \\(MAFIKENG\\)",
               "IKHALA TVET COLLEGE", "LEHANA SS SCHOOL", "JOHN WYCLIFFE CHRISTIAN SCHOOL",
               "VERNON GAMANDA HIGH SCHOOL", "TLHOMELANG SEC", "DELFT SENIOR SECONDARY SCHOOL",
               "TECHNICAL HIGH SCHOOL \\(WELKOM\\)", "H\\.H\\. MAJIZA \\(CISKEI\\)",
               "KHARKHAMS SENIOR SECONDARY SCHOOL", "STAR INTERNATIONAL HIGH SCHOOL",
               "BUCHULE TECH HIGH SCHOOL", "BISHO HIGH", "THE ORACLE ACADEMY",
               "INYIBIBA HIGH \\(FORT BEAUFORT\\)", "ZISUKHANYO SECONDARY SCHOOL",
               "TRINITY HIGH SCHOOL", "MERIDIAN COLLEGE", "CHRISTIAN BROTHERS\\' COLLEGE",
               "ACADEMY FOR CHRISTIAN EDUCATION", "FAIRBAIRN COLLEGE", 
               "DNC COMBINED SCHOOL", "CENTRE OF EXCELLENCE", "FET COLLEGE - SEDIBENG",
               "JAN KRIELSKOOL", "FET COLLEGE - BUFFALO CITY", "KWAKOMANI COMPREHENSIVE S",
               "FET COLLEGE - ESAYIDI", "FET COLLEGE - KING HINTSA", 
               "ST\\. BRENDAN\\'S CATHOLIC SECONDARY", "IMINGCANGATHELO HIGH SCHOOL", 
               "BALMORAL COLLEGE", "FET COLLEGE - LOVEDALE", "SAINT OSWALDS SECONDARY", 
               "KING WILLIAMS TOWN SSS", "NQABARA SS SCHOOL", "SCHOOL OF TOMORROW", 
               "ST ANTHONY\\'S FINISHING SCHOOL", "HO?RSKOOL BERSIG", "FET COLLEGE - EKURHULENI EAST",
               "QUEENSTOWN GHS", "ZANOKHANYO FINISHING SCHOOL", "MIDDELLAND S\\.S", 
               "FET COLLEGE - IKHALA", "KAKAMAS SENIOR SECONDARY SCHOOL", 
               "Boitseanape Technical And Commercial High School", 
               "FET COLLEGE - UMGUNGU-NDLOVU", "DURBAN TECHNICAL COLLEGE", 
               "FET COLLEGE - WATERBERG", "ST MICHAELS FOR GIRLS", "KROONSTAD H/SKOOL", 
               "SAINT ANDREWS \\(BLOEMFONTEIN\\)", "CITRUSDAL HOERSKOOL", 
               "CAMBRIDGE COLLEGE", "BREIBACH", "UPPER GQOGQORA SENIOR SECONDARY",
               "KHANYA \\(CISKEI\\)", "STRAND SEK\\.", "EKURHULENI WEST COLLEGE", 
               "J\\.A\\.CALATA S SCHOOL", "LUGUNYA SENIOR SECONDARY SCHOOL", 
               "HEALTHNICON NURSING COLLEGE", "PROMAT \\(SPRINGS\\)\\)", 
               "PULEDI SECONDARY SCHOOL", "SYMPHONY ROAD SENIOR SECONDARY SCHOOL", 
               "FET COLLEGE - FLAVIUS MAREKA", "ZENITH HIGH SCHOOL", 
               "FET COLLEGE - GERT SIBANDE", "RETREAT HOERSKOOL", 
               "ACADEMIC QUALITY EDUCATION COLLEGE")


getprovince <- function(x) {
  if (is.na(x)) {
    return(NA_character_)
  }
  for (p in provnames) {
    if (regexpr(p, x) != -1) {
      return(p)
    }
  }
  return(x)
}

Vgetprovince <- Vectorize(getprovince)
  
enrdat <- enrdat %>% mutate(PROVINCE = Vgetprovince(`SECONDARY SCHOOL NAME`)) 

enrdat2 <- enrdat %>% 
  mutate(PROVINCE = 
           case_when(PROVINCE %in% c("NORTHERN PROVINCE", "MOLOKE COMBINED SCHOOL", "ST\\. BRENDAN\\'S CATHOLIC SECONDARY", 
                                     "SCHOOL OF TOMORROW", "FET COLLEGE - WATERBERG", "FET COLLEGE - CAPRICORN") ~ "LIMPOPO",
                     PROVINCE %in% c("\\(LANGA\\)", "CAPE TOWN", "NAPHAKADE SECONDARY", "BOSTON HOUSE COLLEGE",
                                     "THEMBALETHU HIGH SCHOOL", "\\(WC\\)", "ATLANTIS", "GUGULETU COMPREHENSIVE", 
                                     "STELLENBOSCH", "MANZOMTHOMBO", "BREERIVIER SENIOR", "WESTON SS",
                                     "KASSELSVLEI", "- WEST COAST", "FALSE BAY", "ST FRANCIS ADULT", "NORTHLINK",
                                     "DESMUND TUTU", "INKWENKWEZI", "IINGCINGA ZETHU", "VISTA NOVASKOOL",
                                     "SITHEMBELE MATISO", "BELLVILLE", "STRAND HS", "POINT HIGH SCHOOL",
                                     "BELVILLE", "ATHLONE SCHOOL FOR THE BLIND", "DELFT SENIOR SECONDARY SCHOOL",
                                     "JOHN WYCLIFFE CHRISTIAN SCHOOL", "KHARKHAMS SENIOR SECONDARY SCHOOL",
                                     "STAR INTERNATIONAL HIGH SCHOOL", "THE ORACLE ACADEMY",
                                     "ZISUKHANYO SECONDARY SCHOOL", "FAIRBAIRN COLLEGE",
                                     "JAN KRIELSKOOL", "ZANOKHANYO FINISHING SCHOOL", 
                                     "CITRUSDAL HOERSKOOL", "CAMBRIDGE COLLEGE", "STRAND SEK\\.", 
                                     "LUGUNYA SENIOR SECONDARY SCHOOL", "HEALTHNICON NURSING COLLEGE",
                                     "SYMPHONY ROAD SENIOR SECONDARY SCHOOL", "RETREAT HOERSKOOL",
                                     "PHANDALWEZI") ~ "WESTERN CAPE",
                     PROVINCE %in% c("DANIELSKUIL HIGH SCHOOL", "NORTH CAPE", "SPRINGBOK", 
                                     "TLHOMELANG SEC", "KENHARDT HIGH SCHOOL", "KAKAMAS SENIOR SECONDARY SCHOOL") ~ "NORTHERN CAPE",
                     PROVINCE %in% c("JOHANNESBURG", "ST MARTIN", "TSHWANE", 
                                     "MIDRAND PARALLEL MEDIUM HIGH", "TRINITY HIGH SCHOOL", "MERIDIAN COLLEGE",
                                     "CHRISTIAN BROTHERS\\' COLLEGE", "FET COLLEGE - SEDIBENG", 
                                     "BALMORAL COLLEGE", "ST ANTHONY\\'S FINISHING SCHOOL", 
                                     "FET COLLEGE - EKURHULENI EAST", "EKURHULENI WEST COLLEGE", 
                                     "PROMAT \\(SPRINGS\\)\\)", "ACADEMIC QUALITY EDUCATION COLLEGE") ~ "GAUTENG",
                     PROVINCE %in% c("RUSTENBURG", "MASCCOM TRAINING CENTRE", "DANVILLE \\(MAFIKENG\\)",
                                     "ACADEMY FOR CHRISTIAN EDUCATION", "HO?RSKOOL BERSIG",
                                     "Boitseanape Technical And Commercial High School",
                                     "LE RONA") ~ "NORTH WEST",
                     PROVINCE %in% c("DR VILJOEN C/S", "HARRISMITH", "TECHNICAL HIGH SCHOOL \\(WELKOM\\)",
                                     "ST MICHAELS FOR GIRLS", "KROONSTAD H/SKOOL", 
                                     "SAINT ANDREWS \\(BLOEMFONTEIN\\)", "FET COLLEGE - FLAVIUS MAREKA",
                                     "ZENITH HIGH SCHOOL") ~ "FREE STATE",
                     PROVINCE %in% c("EAST LONDON", "TRANSKEI", "JONQILIZWE", "KNOWTECH HIGH", "KING SABATA DALINDYEBO", 
                                     "SAKHISIZWE", "COLLEGE-BISHO", "NGCINGWANE TECHNICAL", "E/CAPE", "EASTERN CA", 
                                     "NOMAKA MBEKI", "MARIAZELL", "KING COMMERCIAL", "EASTERN CAP", "PORT ELIZABETH", 
                                     "UMTATA", "- EC\\)", "KHWEZI LOMSO SEC SCHOOL", "BATANDWA NDONDO SSS",
                                     "DIVINE MASTER\\'S ACADEMY", "IKHALA TVET COLLEGE", "INYIBIBA HIGH \\(FORT BEAUFORT\\)",
                                     "LEHANA SS SCHOOL", "VERNON GAMANDA HIGH SCHOOL", "BISHO HIGH",
                                     "H\\.H\\. MAJIZA \\(CISKEI\\)", "BUCHULE TECH HIGH SCHOOL",
                                     "CENTRE OF EXCELLENCE", "FET COLLEGE - BUFFALO CITY", 
                                     "KWAKOMANI COMPREHENSIVE S", "FET COLLEGE - KING HINTSA",
                                     "IMINGCANGATHELO HIGH SCHOOL", "FET COLLEGE - LOVEDALE", 
                                     "KING WILLIAMS TOWN SSS", "NQABARA SS SCHOOL", "QUEENSTOWN GHS",
                                     "MIDDELLAND S\\.S", "FET COLLEGE - IKHALA", "BREIBACH", 
                                     "UPPER GQOGQORA SENIOR SECONDARY", "KHANYA \\(CISKEI\\)",
                                     "J\\.A\\.CALATA S SCHOOL", "LUXOLO HIGH SCHOOL",
                                     "AMAJINGQI SENIOR SECONDARY SCHOOL") ~ "EASTERN CAPE",
                     PROVINCE %in% c("- MAJUBA", "BHEKUZULU HIGH SCHOOL", "KWAFICA", 
                                     "DNC COMBINED SCHOOL", "FET COLLEGE - ESAYIDI", 
                                     "SAINT OSWALDS SECONDARY", "FET COLLEGE - UMGUNGU-NDLOVU",
                                     "DURBAN TECHNICAL COLLEGE", "FET COLLEGE - THEKWINI") ~ "KWAZULU-NATAL",
                     PROVINCE %in% c("FET COLLEGE - NKANGALA", "PULEDI SECONDARY SCHOOL", 
                                     "FET COLLEGE - GERT SIBANDE") ~ "MPUMALANGA",
                     PROVINCE %in% provnames9 ~ PROVINCE,
                     TRUE ~ NA_character_))

enrdat2 <- enrdat2 %>% 
  select(-`SECONDARY SCHOOL NAME`)
  
# ,
# col_types = c("numeric", "numeric", "numeric", "text", "numeric", "text", "text", "text", "text", "text", 
#               "numeric", "text", "text", "text", "text", "numeric", "text", "date", "text", "numeric",
#               rep("text", 6), "numeric", rep("text", 2), "numeric", "text", "numeric", "text", 
#               "numeric", "numeric", "text", "text", "text", "numeric", "numeric", "text", "text", "text", 
#               "date", "text", "text", "date", rep("text", 3), "numeric", rep("text", 3))
curdat <- read_excel("0_Undergraduate_Curriculum_6Sep2023.xlsx",
                     skip = 2L) %>% 
  rename_with(.fn = toupper) %>% 
  select(-c(`QUAL FACULTY SCHOOL`, `QUAL DEPT CODE`,
            `QUALIFICATION TYPE CODE`, `MAJOR AREA`, `PHASE OUT DATE`, 
            `SAPSE COURSE LEVEL DESCRIPTION`)) %>% 
  rename(`COMPULSORY Y N` = `COMPULSARY Y N`)
# col_types = c(rep("numeric", 2L), "text", "numeric", "text",
#               "numeric", rep("text", 8L), "numeric", 
#               rep("text", 2L), "numeric", rep("text", 2L),
#               rep("numeric", 2L), rep("text", 4L),
#               "numeric", rep("text", 2L), rep("numeric", 3L),
#               "text", "date", "date")
save(resdat, enrdat2, curdat, 
     file = paste0("enrollments_residence_curriculum_", Sys.Date(), ".RData"))

acadat <- read_delim("List of Enrolments and subjects 2015-2022.txt", delim = "\t") %>% 
  select(-c(SURNAME, FIRST_NAMES, INITIALS, CITIZEN_CODE, FACULTY, DEPARTMENT, 
            CAMPUS_CODE, CANCEL_DATE, CANCELLATION_REASON, REASON_TO_CANCEL)) %>% 
  mutate(IDEN = hash_sha256(STUDENT),
         TRANSACTION_DATE = as.Date(TRANSACTION_DATE, format = "%d/%b/%y")) %>% 
  relocate(IDEN) %>% 
  select(-c(STUDENT, ETHNIC_GROUP, GENDER, COUNTRY))

save(acadat, file = paste0("academic_records_", Sys.Date(), ".RData"))

gc()

appyears <- 2019:2023

appdatlist <- lapply(seq_along(appyears), function(i) {
  print(i)
  read_delim(paste0("List of Applicants with matric results YR=", appyears[i], ".txt"),
             delim = "\t") %>% 
    select(-c(SURNAME, FIRST_NAMES, INITIALS, CITIZEN_CODE, FACULTY, DEPARTMENT, 
              CAMPUS_CODE, ADMITS, MATRIC_TYPE, MATRIC_SUBJECT_CODE)) %>% 
    mutate(IDEN = hash_sha256(STUDENT),
           TRANSACTION_DATE = as.Date(TRANSACTION_DATE, format = "%d/%b/%y")) %>% 
    relocate(IDEN) %>% 
    select(-STUDENT)
})

appdat <- rbindlist(appdatlist) %>% as_tibble
rm(appdatlist)
gc()


# Get all matric subjects in their own columns
appdat <- appdat %>% 
  mutate(MATRIC_SUBJECT_LEVEL = case_when(
     regexpr("\\(NSC", MATRIC_SUBJECT_NAME) != -1 ~ "NSC",
     regexpr("\\(HG\\)", MATRIC_SUBJECT_NAME) != -1 ~ "HG",
     regexpr(" HG$", MATRIC_SUBJECT_NAME) != -1 ~ "HG",
     regexpr("\\(SG\\)", MATRIC_SUBJECT_NAME) != -1 ~ "SG",
     regexpr(" SG$", MATRIC_SUBJECT_NAME) != -1 ~ "SG",
     regexpr(" LG$", MATRIC_SUBJECT_NAME) != -1 ~ "LG",
     regexpr("\\(LG\\)", MATRIC_SUBJECT_NAME) != -1 ~ "LG",
     regexpr("\\(NCV3\\)", MATRIC_SUBJECT_NAME) != -1 ~ "NCV3",
     regexpr("\\(NCV4\\)", MATRIC_SUBJECT_NAME) != -1 ~ "NCV4",
     regexpr("\\(NCV2\\)", MATRIC_SUBJECT_NAME) != -1 ~ "NCV2",
     regexpr(" N1$", MATRIC_SUBJECT_NAME) != -1 ~ "N1",
     regexpr(" N2$", MATRIC_SUBJECT_NAME) != -1 ~ "N2",
     regexpr(" N3$", MATRIC_SUBJECT_NAME) != -1 ~ "N3",
     regexpr(" N4$", MATRIC_SUBJECT_NAME) != -1 ~ "N4",
     regexpr(" N5$", MATRIC_SUBJECT_NAME) != -1 ~ "N5",
     regexpr(" N6$", MATRIC_SUBJECT_NAME) != -1 ~ "N6",
     regexpr("\\(N5\\)", MATRIC_SUBJECT_NAME) != -1 ~ "N5",
     regexpr("O-LEVEL", MATRIC_SUBJECT_NAME) != -1 ~ "O-LEVEL",
     regexpr("A-LEVEL", MATRIC_SUBJECT_NAME) != -1 ~ "A-LEVEL",
     regexpr("ADVANCED LEVEL", MATRIC_SUBJECT_NAME) != -1 ~ "A-LEVEL",
      TRUE ~ NA_character_),
     FINAL_YEAR_PERC = if_else(FINAL_YEAR_PERC > 100, NA_real_, FINAL_YEAR_PERC))

appdat <- appdat %>% 
  mutate(PERCENT_MARK = case_when(
    !is.na(FINAL_YEAR_PERC) ~ FINAL_YEAR_PERC,
    is.na(FINAL_YEAR_SYMBOL) ~ NA_real_,
    (suppressWarnings(!is.na(as.numeric(FINAL_YEAR_SYMBOL))) & 
      nchar(FINAL_YEAR_SYMBOL) == 2L) ~ as.numeric(FINAL_YEAR_SYMBOL),
     FINAL_YEAR_SYMBOL %in% c("A", "7") ~ mean(c(80, 100)),
     FINAL_YEAR_SYMBOL %in% c("B", "6") ~ mean(c(70, 79)),
     FINAL_YEAR_SYMBOL %in% c("C", "5") ~ mean(c(60, 69)),
     FINAL_YEAR_SYMBOL %in% c("D", "4") ~ mean(c(50, 59)),
     FINAL_YEAR_SYMBOL %in% c("E", "3") ~ mean(c(40, 49)),
     FINAL_YEAR_SYMBOL %in% c("F", "2") ~ mean(c(30, 39)),
     FINAL_YEAR_SYMBOL == "1" ~ mean(c(0, 29)),
     FINAL_YEAR_SYMBOL == "G" ~ mean(c(20, 29)),
     FINAL_YEAR_SYMBOL == "H" ~ mean(c(10, 19)),
     FINAL_YEAR_SYMBOL == "I" ~ mean(c(0, 9)),
     FINAL_YEAR_SYMBOL %in% c("0", "NV", "FF", "GG") ~ NA_real_,
    TRUE ~ NA_real_))

# Only consider highest mark for each specific matric subject
appdat1 <- appdat %>%
  group_by(across(.cols = c(IDEN:MATRIC_SUBJECT_NAME, TRANSACTION_DATE, 
                            MATRIC_SUBJECT_LEVEL))) %>% 
  summarise(PERCENT_MARK = max(PERCENT_MARK, na.rm = TRUE)) %>% 
  ungroup

save(appdat, file = "appdat.RData")
rm(appdat)
gc()

save(appdat1, file = "appdat1.RData")

appdat2 <- appdat1 %>% 
  rename("YEAR_APPLIED_FOR" = "YEAR") %>% 
  mutate(MATRIC_YEAR = substr(MATRIC_DATE, 1, 4) %>% as.integer,
    MATRIC_SUBJECT_NAME2 = 
           str_replace(MATRIC_SUBJECT_NAME, 
            pattern = c("\\(NSC\\)|\\(SG\\)|\\(HG\\)|\\(LG\\)|\\(NCV3\\)|\\(NCV2\\)|\\(NCV4\\)|\\(NCV5\\)| N3| N4| N2| N1| N5| ADVANCED LEVEL| A-LEVEL| O-LEVEL|\\(NSC$| HG| SG| LG"), replacement = "") %>% str_trim) %>% 
  mutate(MATRIC_SUBJECT_NAME2 = 
    case_when(MATRIC_SUBJECT_NAME2 %in% c("LIFE ORIENTATION", "MATHEMATICS", "GEOGRAPHY",
              "MATHEMATICAL LITERACY", "BUSINESS STUDIES", "HISTORY", "ECONOMICS", "ACCOUNTING",
              "AGRICULTURAL SCIENCE", "TOURISM", "COMPUTER APPLIC TECHN", "CONSUMER STUDIES",
              "ENG GRAPHICS & DESIGN", "TECHNICAL MATHEMATICS") ~ MATRIC_SUBJECT_NAME2,
              MATRIC_SUBJECT_NAME2 %in% c("PHYSICS", "PHYSICAL SCIENCE", "PHYSICAL SCIENCES") ~ "PHYSICAL SCIENCES",
              MATRIC_SUBJECT_NAME2 %in% c("LIFE SCIENCES", "BIOLOGY") ~ "LIFE SCIENCES",
              MATRIC_SUBJECT_NAME2 %in% c("ENGLISH HOME LANGUAGE", "ENGLISH FIRST LANGUAGE") ~ "ENGLISH HOME LANGUAGE",
              MATRIC_SUBJECT_NAME2 %in% c("ENGLISH SECOND LANGUAGE", "ENGLISH 2ND ADDIT LANGUAGE",
                                          "ENGLISH 2ND ADDIT LANG",
                                          "ENGLISH 1ST ADDIT. LANG") ~ "ENGLISH ADDIT LANGUAGE",
              MATRIC_SUBJECT_NAME2 %in% c("BUSINESS ECONOMICS", "ECONOMICS") ~ "ECONOMICS",
              MATRIC_SUBJECT_NAME2 %in% c("ISIXHOSA HOME LANGUAGE", "ISINDEBELE HOME LANGUAGE",
                                          "ISIZULU HOME LANGUAGE", "SISWATI HOME LANGUAGE",
                                          "SESOTHO HOME LANGUAGE", "SETSWANA HOME LANGUAGE",
                                          "XITSONGA HOME LANGUAGE", "AFRIKAANS HOME LANGUAGE",
                                          "TSHIVENDA HOME LANGUAGE", "SEPEDI HOME LANGUAGE") ~ "RSA LANGUAGE",
              MATRIC_SUBJECT_NAME2 %in% c("ISIXHOSA 2ND ADDIT LANG", "ISIXHOSA 1ST ADDIT LANG", 
                                          "ISINDEBELE 1ST ADDIT LANG", "ISINDEBELE 2ND ADDIT LANG",
                                          "ISIZULU 1ST ADDIT LANG", "ISIZULU 2ND ADDIT LANG", 
                                          "SISWATI 1ST ADDIT LANG", "SISWATI 2ND ADDIT LANG",
                                          "SESOTHO 1ST ADDIT LANG", "SESOTHO 2ND ADDIT LANG", 
                                          "SETSWANA 1ST ADDIT LANG", "SETSWANA 2ND ADDIT LANG",
                                          "XITSONGA 1ST ADDIT LANG", "XITSONGA 2ND ADDIT LANG", 
                                          "AFRIKAANS 1ST ADDIT LANG", "AFRIKAANS 2ND ADDIT LANG",
                                          "AFRIKAANS 1ST ADD. LANG", "AFRIKAANS 2ND ADDIT.LANG",
                                          "AFRIKAANS SECOND LANGUAGE",
                                          "TSHIVENDA 1ST ADDIT LANG", "TSHIVENDA 2ND ADDIT LANG",  
                                          "SEPEDI 1ST ADDIT LANG", "SEPEDI 2ND ADDIT LANG") ~ "RSA LANGUAGE",
              str_starts(MATRIC_SUBJECT_NAME2, "AFRIKAANS") | 
                str_starts(MATRIC_SUBJECT_NAME2, "ISIXHOSA") |
                str_starts(MATRIC_SUBJECT_NAME2, "ISIZULU") |
                str_starts(MATRIC_SUBJECT_NAME2, "ISINDEBELE") |
                str_starts(MATRIC_SUBJECT_NAME2, "ZULU") |
                str_starts(MATRIC_SUBJECT_NAME2, "XHOSA") |
                str_starts(MATRIC_SUBJECT_NAME2, "XITSONGA") |
                str_starts(MATRIC_SUBJECT_NAME2, "TSONGA") |
                str_starts(MATRIC_SUBJECT_NAME2, "TSWANA") |
                str_starts(MATRIC_SUBJECT_NAME2, "TSHIVENDA") |
                str_starts(MATRIC_SUBJECT_NAME2, "VENDA") |
                str_starts(MATRIC_SUBJECT_NAME2, "XITSONGA") |
                str_starts(MATRIC_SUBJECT_NAME2, "SWAZI") |
                str_starts(MATRIC_SUBJECT_NAME2, "SISWATI") |
                str_starts(MATRIC_SUBJECT_NAME2, "SISWAZI") |
                str_starts(MATRIC_SUBJECT_NAME2, "SESOTHO") |
                str_starts(MATRIC_SUBJECT_NAME2, "SOUTH SOTHO") |
                str_starts(MATRIC_SUBJECT_NAME2, "SETSWANA") |
                str_starts(MATRIC_SUBJECT_NAME2, "SESTSWANA") |
                str_starts(MATRIC_SUBJECT_NAME2, "SESETHO") |
                str_starts(MATRIC_SUBJECT_NAME2, "SEPEDI") |
                str_starts(MATRIC_SUBJECT_NAME2, "NORTH SOTHO") ~ "RSA LANGUAGE",
              TRUE ~ "OTHER"
              )) %>% 
  select(-c(MATRIC_SUBJECT_NAME, MATRIC_DATE)) %>% 
  mutate(MATHS_TYPE = case_when(
    MATRIC_SUBJECT_NAME2 == "MATHEMATICS" ~ "MATHEMATICS",
    MATRIC_SUBJECT_NAME2 == "TECHNICAL MATHEMATICS" ~ "TECHNICAL",
    MATRIC_SUBJECT_NAME2 == "MATHEMATICAL LITERACY" ~ "MATHS LIT",
    TRUE ~ NA_character_
  ),
  ENGLISH_TYPE = case_when(
    MATRIC_SUBJECT_NAME2 == "ENGLISH HOME LANGUAGE" ~ "HOME",
    MATRIC_SUBJECT_NAME2 == "ENGLISH ADDIT LANGUAGE" ~ "ADDITIONAL",
    TRUE ~ NA_character_
  ),
  MATRIC_SUBJECT_NAME2 = case_when(
    MATRIC_SUBJECT_NAME2 %in% c("MATHEMATICS", "MATHEMATICAL LITERACY", 
                                "TECHNICAL MATHEMATICS") ~ "MATHS",
    MATRIC_SUBJECT_NAME2 %in% c("ENGLISH HOME LANGUAGE", "ENGLISH ADDIT LANGUAGE") ~ "ENGLISH",
    TRUE ~ MATRIC_SUBJECT_NAME2
  ))
  
# group_by(Student.Number, Matric.Date, 
#          Matric.Subject.Name, Did.Pure.Mathematics, 
#          Did.English.Home.Language, 
#          Secondary.School.Quintile, Province) %>% 
#   summarise(Final.Year.Perc = mean(Final.Year.Perc), .groups = "keep") %>% 
#   rename(Pct_Mark = Final.Year.Perc) %>% 
#   arrange(Student.Number, desc(Matric.Date)) %>% 
#   distinct(Student.Number, Matric.Subject.Name, .keep_all = TRUE) %>%
#   pivot_wider(names_from = Matric.Subject.Name,
#               values_from = Pct_Mark)

#   IDEN, ETHNIC_GROUP, GENDER, COUNTRY, FACULTY_NAME,
# DEPARTMENT_NAME, YEAR_APPLIED_FOR, QUALIFICATION, QUALIFICATION_DESCRIPTION,
# BLOCK_CODE, OFFERING_TYPE, CAMPUS_NAME, 
# PERIOD_OF_STUDY, CHOICE, ADMIT_Y_N, ADMIT_STATUS_NAME,
# SCHOOL_NAME, SECONDARY_SCHOOL_QUINTILE, TRANSACTION_DATE,
# MATRIC_SUBJECT_NAME2, MATHS_TYPE, ENGLISH_TYPE

names(appdat2)

appdat3 <- appdat2 %>% 
  mutate(PERCENT_MARK = if_else(is.infinite(PERCENT_MARK), NA_real_, PERCENT_MARK)) %>%
  group_by(across(.cols = c(IDEN:MATRIC_SUBJECT_LEVEL, MATRIC_SUBJECT_NAME2,
                            MATHS_TYPE, ENGLISH_TYPE))) %>% 
  summarise(PERCENT_MARK = mean(PERCENT_MARK, na.rm = TRUE), .groups = "keep") %>% 
  ungroup

appdat3 <- appdat3 %>% 
  arrange(IDEN) %>% 
  mutate(PERCENT_MARK = if_else(is.nan(PERCENT_MARK), NA_real_, 
                                PERCENT_MARK)) %>%
  mutate(SCHOOL_NAME = utf8_encode(SCHOOL_NAME)) %>%
  mutate(SCHOOL_NAME = gsub(pattern = "KWA-ZULU|KWAZULA NATAL|KWAZULU  NATAL|- KZN|KWAZULU NATAL|KWA ZULU NATAL|KWAZULU - NATAL|KEAZULU NATAL|DURBAN|MOBENI|Pietermaritzburg",
                                        replacement = "KWAZULU-NATAL", x = SCHOOL_NAME) %>% 
           gsub(pattern = "FREESTATE", replacement = "FREE STATE") %>% 
           gsub(pattern = "NORTHEN CAPE|- NC\\)|NORTH CAPE", replacement = "NORTHERN CAPE") %>% 
           gsub(pattern = "NORTH-WEST|RUSTENBURG", replacement = "NORTH WEST") %>% 
           gsub(pattern = "-EC|- EC\\)|\\(EC\\)|UITENHAGE|PORT ELIZABETH|UMTATA", replacement = "EASTERN CAPE") %>% 
           gsub(pattern = "NORTHERN PROVINCE", replacement = "LIMPOPO") %>% 
           gsub(pattern = "\\(WC\\)|CAPE TOWN", replacement = "WESTERN CAPE"))

appdat3 <- appdat3 %>% 
  mutate(PROVINCE = Vgetprovince(SCHOOL_NAME)) %>% 
  mutate(PROVINCE = 
         case_when(PROVINCE %in% c("NORTHERN PROVINCE", "MOLOKE COMBINED SCHOOL", "ST\\. BRENDAN\\'S CATHOLIC SECONDARY", 
                                   "SCHOOL OF TOMORROW", "FET COLLEGE - WATERBERG", "FET COLLEGE - CAPRICORN") ~ "LIMPOPO",
                   PROVINCE %in% c("\\(LANGA\\)", "CAPE TOWN", "NAPHAKADE SECONDARY", "BOSTON HOUSE COLLEGE",
                                   "THEMBALETHU HIGH SCHOOL", "\\(WC\\)", "ATLANTIS", "GUGULETU COMPREHENSIVE", 
                                   "STELLENBOSCH", "MANZOMTHOMBO", "BREERIVIER SENIOR", "WESTON SS",
                                   "KASSELSVLEI", "- WEST COAST", "FALSE BAY", "ST FRANCIS ADULT", "NORTHLINK",
                                   "DESMUND TUTU", "INKWENKWEZI", "IINGCINGA ZETHU", "VISTA NOVASKOOL",
                                   "SITHEMBELE MATISO", "BELLVILLE", "STRAND HS", "POINT HIGH SCHOOL",
                                   "BELVILLE", "ATHLONE SCHOOL FOR THE BLIND", "DELFT SENIOR SECONDARY SCHOOL",
                                   "JOHN WYCLIFFE CHRISTIAN SCHOOL", "KHARKHAMS SENIOR SECONDARY SCHOOL",
                                   "STAR INTERNATIONAL HIGH SCHOOL", "THE ORACLE ACADEMY",
                                   "ZISUKHANYO SECONDARY SCHOOL", "FAIRBAIRN COLLEGE",
                                   "JAN KRIELSKOOL", "ZANOKHANYO FINISHING SCHOOL", 
                                   "CITRUSDAL HOERSKOOL", "CAMBRIDGE COLLEGE", "STRAND SEK\\.", 
                                   "LUGUNYA SENIOR SECONDARY SCHOOL", "HEALTHNICON NURSING COLLEGE",
                                   "SYMPHONY ROAD SENIOR SECONDARY SCHOOL", "RETREAT HOERSKOOL",
                                   "PHANDALWEZI") ~ "WESTERN CAPE",
                   PROVINCE %in% c("DANIELSKUIL HIGH SCHOOL", "NORTH CAPE", "SPRINGBOK", 
                                   "TLHOMELANG SEC", "KENHARDT HIGH SCHOOL", "KAKAMAS SENIOR SECONDARY SCHOOL") ~ "NORTHERN CAPE",
                   PROVINCE %in% c("JOHANNESBURG", "ST MARTIN", "TSHWANE", 
                                   "MIDRAND PARALLEL MEDIUM HIGH", "TRINITY HIGH SCHOOL", "MERIDIAN COLLEGE",
                                   "CHRISTIAN BROTHERS\\' COLLEGE", "FET COLLEGE - SEDIBENG", 
                                   "BALMORAL COLLEGE", "ST ANTHONY\\'S FINISHING SCHOOL", 
                                   "FET COLLEGE - EKURHULENI EAST", "EKURHULENI WEST COLLEGE", 
                                   "PROMAT \\(SPRINGS\\)\\)", "ACADEMIC QUALITY EDUCATION COLLEGE") ~ "GAUTENG",
                   PROVINCE %in% c("RUSTENBURG", "MASCCOM TRAINING CENTRE", "DANVILLE \\(MAFIKENG\\)",
                                   "ACADEMY FOR CHRISTIAN EDUCATION", "HO?RSKOOL BERSIG",
                                   "Boitseanape Technical And Commercial High School",
                                   "LE RONA") ~ "NORTH WEST",
                   PROVINCE %in% c("DR VILJOEN C/S", "HARRISMITH", "TECHNICAL HIGH SCHOOL \\(WELKOM\\)",
                                   "ST MICHAELS FOR GIRLS", "KROONSTAD H/SKOOL", 
                                   "SAINT ANDREWS \\(BLOEMFONTEIN\\)", "FET COLLEGE - FLAVIUS MAREKA",
                                   "ZENITH HIGH SCHOOL") ~ "FREE STATE",
                   PROVINCE %in% c("EAST LONDON", "TRANSKEI", "JONQILIZWE", "KNOWTECH HIGH", "KING SABATA DALINDYEBO", 
                                   "SAKHISIZWE", "COLLEGE-BISHO", "NGCINGWANE TECHNICAL", "E/CAPE", "EASTERN CA", 
                                   "NOMAKA MBEKI", "MARIAZELL", "KING COMMERCIAL", "EASTERN CAP", "PORT ELIZABETH", 
                                   "UMTATA", "- EC\\)", "KHWEZI LOMSO SEC SCHOOL", "BATANDWA NDONDO SSS",
                                   "DIVINE MASTER\\'S ACADEMY", "IKHALA TVET COLLEGE", "INYIBIBA HIGH \\(FORT BEAUFORT\\)",
                                   "LEHANA SS SCHOOL", "VERNON GAMANDA HIGH SCHOOL", "BISHO HIGH",
                                   "H\\.H\\. MAJIZA \\(CISKEI\\)", "BUCHULE TECH HIGH SCHOOL",
                                   "CENTRE OF EXCELLENCE", "FET COLLEGE - BUFFALO CITY", 
                                   "KWAKOMANI COMPREHENSIVE S", "FET COLLEGE - KING HINTSA",
                                   "IMINGCANGATHELO HIGH SCHOOL", "FET COLLEGE - LOVEDALE", 
                                   "KING WILLIAMS TOWN SSS", "NQABARA SS SCHOOL", "QUEENSTOWN GHS",
                                   "MIDDELLAND S\\.S", "FET COLLEGE - IKHALA", "BREIBACH", 
                                   "UPPER GQOGQORA SENIOR SECONDARY", "KHANYA \\(CISKEI\\)",
                                   "J\\.A\\.CALATA S SCHOOL", "LUXOLO HIGH SCHOOL",
                                   "AMAJINGQI SENIOR SECONDARY SCHOOL") ~ "EASTERN CAPE",
                   PROVINCE %in% c("- MAJUBA", "BHEKUZULU HIGH SCHOOL", "KWAFICA", 
                                   "DNC COMBINED SCHOOL", "FET COLLEGE - ESAYIDI", 
                                   "SAINT OSWALDS SECONDARY", "FET COLLEGE - UMGUNGU-NDLOVU",
                                   "DURBAN TECHNICAL COLLEGE", "FET COLLEGE - THEKWINI") ~ "KWAZULU-NATAL",
                   PROVINCE %in% c("FET COLLEGE - NKANGALA", "PULEDI SECONDARY SCHOOL", 
                                   "FET COLLEGE - GERT SIBANDE") ~ "MPUMALANGA",
                   PROVINCE %in% provnames9 ~ PROVINCE,
                   TRUE ~ NA_character_)) %>% 
  select(-SCHOOL_NAME)

save(appdat3, file = "appdat3.RData")

appdat4 <- appdat3 %>% 
  group_by(across(c(IDEN:TRANSACTION_DATE))) %>%
  fill(MATHS_TYPE, ENGLISH_TYPE, .direction = "updown") %>%
  ungroup 

appdat_pivot <- appdat4 %>% 
  rename("SCHOOL_PROVINCE" = "PROVINCE") %>% 
  pivot_wider(names_from = MATRIC_SUBJECT_NAME2,
          values_from = PERCENT_MARK)

rm(appdat2, appdat3)
gc()

appdat <- appdat_pivot %>% 
  relocate(ENGLISH, ENGLISH_TYPE, MATHS, MATHS_TYPE,
           `LIFE ORIENTATION`, `LIFE SCIENCES`, `PHYSICAL SCIENCES`,
           GEOGRAPHY, `BUSINESS STUDIES`, HISTORY, 
           ECONOMICS, ACCOUNTING, TOURISM, `AGRICULTURAL SCIENCE`,
           `COMPUTER APPLIC TECHN`, `CONSUMER STUDIES`,
           `ENG GRAPHICS & DESIGN`, OTHER,
           .after = SCHOOL_PROVINCE)


save(appdat, file = "appdat.RData")