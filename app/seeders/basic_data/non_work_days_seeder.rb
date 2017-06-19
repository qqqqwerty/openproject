module BasicData
  class NonWorkDaysSeeder < Seeder
    def seed_data!
      NonWorkDay.transaction do
        data.each do |attributes|
          NonWorkDay.create(attributes)
        end
      end
    end

    def applicable?
      NonWorkDay.all.empty?
    end

    def not_applicable_message
      'Skipping non work days as there are already some configured'
    end

    def data
      [
        { date: Date.parse("2017-06-04")   },
        { date: Date.parse("2017-06-24")   },
        { date: Date.parse("2017-07-06")   },
        { date: Date.parse("2017-08-15")   },
        { date: Date.parse("2017-11-01")   },
        { date: Date.parse("2017-12-24")   },
        { date: Date.parse("2017-12-25")   },
        { date: Date.parse("2017-12-26")   },
        { date: Date.parse("2018-01-01")   },
        { date: Date.parse("2018-02-16")   },
        { date: Date.parse("2018-03-11")   },
        { date: Date.parse("2018-04-01")   },
        { date: Date.parse("2018-04-02")   },
        { date: Date.parse("2018-05-01")   },
        { date: Date.parse("2018-05-06")   },
        { date: Date.parse("2018-06-03")   },
        { date: Date.parse("2018-06-24")   },
        { date: Date.parse("2018-07-06")   },
        { date: Date.parse("2018-08-15")   },
        { date: Date.parse("2018-11-01")   },
        { date: Date.parse("2018-12-24")   },
        { date: Date.parse("2018-12-25")   },
        { date: Date.parse("2018-12-26")   }
      ]
    end
  end
end