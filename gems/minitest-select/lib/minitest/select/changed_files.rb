module Minitest
  module Select
    class ChangedFiles
      def to_a
        `git --no-pager diff --merge-base --name-only main`.lines.map!(&:squish)
      end
    end
  end
end
