require 'minitest/autorun'
require 'test/unit'
require "brm-jruby"

class BRMJRubyTest < Minitest::Test
#class BRMJRubyTest < Test::Unit::TestCase
    def test_poid
    poid = com.portal.pcm.Poid.from_str('0.0.0.5 /service/pcm_client -1')
    assert(poid.db == 5)
    assert(poid.type == '/service/pcm_client')
    assert(poid.id == -1)
  end

  def test_flist_set
    flist = com.portal.pcm.FList.new
    flist.xset("Name", "Bob")
    assert(flist["Name"] == "Bob")

    actual = flist["Name"] = "Joe"
    assert(actual == "Joe")
    assert(flist["Name"] == "Joe")

    poid = com.portal.pcm.Poid.from_str('0.0.0.5 /service/pcm_client -1')
    poidx = com.portal.pcm.Poid.from_str('0.0.5.5 /service/pcm_client -1')

    flist.set(com.portal.pcm.fields.FldPoid.getInst,poid)
    assert(flist['PIN_FLD_POID'] === poid)
    assert(flist['PIN_FLD_POID'] != poidx)

    flist['PIN_FLD_POID'] = poid
    assert(flist['PIN_FLD_POID'] === poid)
    assert(flist['PIN_FLD_POID'] != poidx)

    flist.xset('Poid', poid)
    assert(flist['PIN_FLD_POID'] === poid)
    assert(flist['PIN_FLD_POID'] != poidx)

    flist.xset("AccountObj", Poid.from_str('0.0.0.3 /account -123'))
    flist['ServiceObj'] = Poid.from_str('0.0.0.4 /account -789')
    assert(Java::ComPortalPcm::FList === flist.xset("Poid", "0.0.0.5 /dummy -1"))
  end

  def test_flist_from_str
    v1, v2 = 'Bob', 'Description'
    doc = com.portal.pcm.FList.new.xset('Name', v1).xset('Descr', v2).to_s
    flist = com.portal.pcm.FList.from_str("\n\t\n" + doc + "\n\n")
    assert(flist['PIN_FLD_NAME'] == v1)
    assert(flist['PIN_FLD_DESCR'] == v2)
  end

  def test_flist_from_hash
    flist = com.portal.pcm.FList.from_hash("Name" => "Bob", PIN_FLD_DESCR: "Description")
    assert(flist['PIN_FLD_NAME'] == 'Bob')
  end


end
