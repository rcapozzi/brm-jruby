require "test/unit"
require "brm-jruby"

class TestJflist < Test::Unit::TestCase

  def test_poid
    flist = com.portal.pcm.FList.new
    poid = com.portal.pcm.Poid.from_str('0.0.0.5 /service/pcm_client -1')
    assert(poid.db == 5)
    assert(poid.type == '/service/pcm_client')
    assert(poid.id == -1)
    flist.set(com.portal.pcm.fields.FldPoid.getInst,poid)
  end
end
