require 'test_helper'
require 'search_helper'

class SearchHelperTest < ActiveSupport::TestCase
  include SearchHelper
  test "ElasticProcessor测试" do
    assert_equal "domain:(*360.cn*)", ElasticProcessor.parse('domain="360.cn"')
    assert_equal "( domain:(*360.cn*) && host:(*webscan.360.cn*) )", ElasticProcessor.parse('domain="360.cn" && host="webscan.360.cn"')
    assert_equal "( title:(*PES2016*) && -host:(*bbs*) )", ElasticProcessor.parse('title="PES2016" && host!="bbs"')
    assert_equal "lastupdatetime:([\"2015\\-08\\-05 00\\:00\\:00\" TO *])", ElasticProcessor.parse('lastupdatetime>"2015-08-05 00:00:00"')
    assert_equal "( host:(*webscan.360.cn*) || host:(*wangzhan.360.cn*) )", ElasticProcessor.parse('host="webscan.360.cn" || host="wangzhan.360.cn"')

    assert_equal "( ( ( host:(*webscan.360.cn*) || host:(*wangzhan.360.cn*) ) && title:(*网站安全*) ) && -title:(*检测*) )", ElasticProcessor.parse('((host="webscan.360.cn" || host="wangzhan.360.cn") && title="网站安全") && title!="检测"')
  end
end
