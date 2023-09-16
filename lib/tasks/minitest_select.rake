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

  desc "Run integration tests for ignored files"
  task ignored_files: :environment do
    Dir.chdir(File.join(__dir__, "../../gems/minitest-select")) do
      system("rake test TEST=test/integration/ignore_files_test.rb")
    end
  end

  desc "Run integration tests for always selected files"
  task always_select: :environment do
    Dir.chdir(File.join(__dir__, "../../gems/minitest-select")) do
      system("rake test TEST=test/integration/always_select_test.rb")
    end
  end

  desc "Run integration tests for glob rule files"
  task glob_rule: :environment do
    Dir.chdir(File.join(__dir__, "../../gems/minitest-select")) do
      system("rake test TEST=test/integration/glob_rule_test.rb")
    end
  end

end
