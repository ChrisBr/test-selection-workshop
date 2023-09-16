namespace :minitest_select do
  desc "Run integration tests for chapter one"
  task chapter_one: :environment do
    Dir.chdir(File.join(__dir__, "../../gems/minitest-select")) do
      system("rake test TEST=test/integration/chapter_one_test.rb")
    end
  end

  desc "Run integration tests for chapter two"
  task chapter_two: :environment do
    Dir.chdir(File.join(__dir__, "../../gems/minitest-select")) do
      system("rake test TEST=test/integration/chapter_two_test.rb")
    end
  end

  desc "Run integration tests for chapter three"
  task chapter_three: :environment do
    Dir.chdir(File.join(__dir__, "../../gems/minitest-select")) do
      system("rake test TEST=test/integration/chapter_three_test.rb")
    end
  end
end
