# API changes description for MIS developers.

## Create Employee Request
**POST** http://ehealth.demo/api/employee_requests

### Request:
```json
{
  "employee_request": {
    "division_id": "9fd11efb-3f80-41d6-9612-e1beb44baa9c",
    "position": "Посада згідно штатного розкладу",
    "start_date": "2017-09-05",
    "end_date": "2019-03-05",
    "status": "NEW",
    "employment_status": "INTERNSHIP",
    "employee_category": "SPECIALIST",
    "employee_type": "DOCTOR",
    "position_level": "SPECIALIST_DOCTOR",
    "speciality_nomenclature": "ALLERGIST",
    "dk_code": "2221.2",
    "provided_services": [
      {
        "type": "HIV",
        "sub_types": [ {"title": "ARV", "additional": "reserved"} ]
      },
      {
        "type": "HIV",
        "sub_types": [ {"title": "SMT", "additional": "reserved"} ]
      }
    ],
    "party": {
      "first_name": "Іван",
      "last_name": "Алопо",
      "second_name": "Труш",
      "birth_date": "1980-09-19",
      "birth_country": "UA",
      "birth_settlement": "Говтва",
      "birth_settlement_type": "SETTLEMENT",
      "citizenship": "UA",
      "citizenship_at_birth": "UA",
      "gender": "MALE",
      "tax_id": "АН321518",
      "no_tax_id": true,
      "photo": "http://imgur.com",
      "email": "ehealth.demo42@gmail.com",
      "personal_email": "goofy@demo.com",
      "language_skills": [
      	{
          "language": "UA",
          "language_level": "PROFICIENT"
        },
        {
          "language": "EN",
          "language_level": "INTERMEDIATE"
        }
      ],
      "retirement": [
        {
          "type": "OLD_AGE",
          "date": "2017-01-20"
        },
        {
          "type": "DISABILITY",
          "date": "2018-02-13"
        }
      ],
      "addresses": [
      	{
      	  "type": "RESIDENCE",
      	  "country": "UA",
      	  "area": "DP",
      	  "region": "DP",
      	  "settlement": "Dnipro",
      	  "settlement_type": "CITY",
      	  "street": "Sadova",
      	  "apartment": "24",
      	  "street_type": "STREET",
      	  "zip": "12342",
      	  "building": "28"
      	},
      	{
      	  "type": "REGISTRATION",
      	  "country": "UA",
      	  "area": "LV",
      	  "region": "LV",
      	  "settlement": "Lviv",
      	  "settlement_type": "CITY",
      	  "street": "Sadova",
      	  "apartment": "24",
      	  "street_type": "STREET",
      	  "zip": "12342",
      	  "building": "42"
      	}
      ],
      "documents": [
        {
          "type": "PASSPORT",
          "number": "321518",
          "issued_by": "RUVD",
          "issued_at": "1988-01-23"
        }
      ],
      "phones": [
        {
          "type": "MOBILE",
          "number": "+380502351978",
          "public": false
        },
		{
          "type": "MOBILE",
          "number": "+380502354978",
          "public": true
        }
      ],
      "about_myself": "тут трохи про себе",
      "working_experience": 3
    },
    "doctor": {
      "educations": [
        {
          "country": "UA",
          "city": "Львів",
          "institution_name": "Академія Богомольця",
          "issued_date": "2017-08-01",
          "diploma_number": "DD123543",
          "degree": "JUNIOR_EXPERT",
          "speciality": "Біологія",
          "speciality_code": "091",
          "form": "FULL_TIME",
          "legalized": true,
          "legalizations": [
            {
              "issued_date": "1988-04-23",
              "number": "AC438942",
              "institution_name": "American Institute of Chemists"
            }
          ]
        }
      ],
      "qualifications": [
        {
          "type": "INTERNSHIP",
          "related_to": {
            "type": "HIV",
            "sub_type": "RESERVED"
          },
          "course_name": "Новітні методи у хірургії",
          "form": "FULL_TIME",
          "duration": "2",
          "duration_units": "WEEKS",
          "results": 0.82,
          "start_date": "2017-06-01",
          "end_date": "2017-06-15",
          "institution_name": "Академія Богомольця",
          "speciality": "Педіатр",
          "issued_date": "2017-08-02",
          "certificate_number": "2017-08-03",
          "valid_to": "2017-10-10",
          "additional_info": "additional info"
        }
      ],
      "specialities": [
        {
          "speciality": "PEDIATRICIAN",
          "speciality_officio": true,
          "level": "SECOND",
          "qualification_type": "AWARDING",
          "attestation_name": "Академія Богомольця",
          "attestation_date": "2017-08-04",
          "valid_to_date": "2017-08-05",
          "certificate_number": "AB/21331",
          "order_date": "2016-02-12",
          "order_number": "X23454",
          "order_institution_name": "Богомольця",
          "attestation_results": "BA"
        },
        {
          "speciality": "PHARMACIST",
          "speciality_officio": false,
          "level": "FIRST",
          "qualification_type": "DEFENSE",
          "attestation_name": "Академія Богомольця",
          "attestation_date": "2017-08-04",
          "valid_to_date": "2017-08-05",
          "certificate_number": "AB/21331",
          "order_date": "2016-02-12",
          "order_number": "X23454",
          "order_institution_name": "Богомольця",
          "attestation_results": "BA"
        }
      ],
      "science_degree": {
        "country": "UA",
        "city": "Київ",
        "academic_status": "PHD",
        "degree": "PHD",
        "degree_country": "UA",
        "degree_city": "Київ",
        "degree_institution_name": "Академія Богомольця",
        "degree_science_domain": "PHYSICS",
        "science_domain": "BIOLOGY",
        "speciality_group": "CLINICAL",
        "code": "14.01.2003",
        "institution_name": "Академія Богомольця",
        "diploma_number": "DD123543",
        "speciality": "Педіатр",
        "issued_date": "2017-08-05"
      }
    }
  }
}
```