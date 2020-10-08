require "test/unit"
require "brm-jruby"

class TestJflist < Test::Unit::TestCase

  def test_poid
    poid = com.portal.pcm.Poid.from_str('0.0.0.5 /service/pcm_client -1')
    assert(poid.db == 5)
    assert(poid.type == '/service/pcm_client')
    assert(poid.id == -1)
  end

  def test_flist
    flist = com.portal.pcm.FList.new
    flist.xset("Name", "Bob")
    assert(flist["Name"] == "Bob")

    actual = flist["Name"] = "Joe"
    assert(actual == "Joe")
    assert(flist["Name"] == "Joe")

    poid = com.portal.pcm.Poid.from_str('0.0.0.5 /service/pcm_client -1')
    flist.set(com.portal.pcm.fields.FldPoid.getInst,poid)
    flist.xset("AccountObj", Poid.from_str('0.0.0.3 /account -123'))
    flist['ServiceObj'] = Poid.from_str('0.0.0.4 /account -789')

    flist.xset("Poid", "0.0.0.5 /dummy -1")
  end
end
