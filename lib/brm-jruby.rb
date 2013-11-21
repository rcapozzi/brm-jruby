#
# JRuby helpers for PCM.
#

# Custom fields should be defined in Infranet.properties.
# infranet.custom.field.package=com.foo
# infranet.custom.field.123=XXX_FLD_FOO
# then require the foo-flds.jar

class BRMJRuby
VERSION = '0.0.1'
end

require 'jruby'
require 'pcm'
require 'pcmext'
include Java

java_import "java.util.Properties"
java_import "com.portal.pcm.FList"
java_import "com.portal.pcm.PortalContext"
java_import "com.portal.pcm.Poid"
java_import "com.portal.pcm.SparseArray"
java_import "com.portal.pcm.Element"

# Import field and name it something we know
java_import ("com.portal.pcm.Field"){|p,c| "PIN_#{c}" }

# Avoid warnings if already required
begin
	Kernel.const_get("PIN_FLDT_INT")
rescue
	PCM_OP_SDK_GET_FLD_SPECS = 575

	PIN_FLDT_UNUSED     = 0
	PIN_FLDT_INT        = 1
	PIN_FLDT_UINT       = 2   
	PIN_FLDT_ENUM       = 3
	PIN_FLDT_NUM        = 4   
	PIN_FLDT_STR        = 5
	PIN_FLDT_BUF        = 6
	PIN_FLDT_POID       = 7
	PIN_FLDT_TSTAMP     = 8
	PIN_FLDT_ARRAY      = 9   
	PIN_FLDT_SUBSTRUCT  = 10  
	PIN_FLDT_OBJ        = 11  
	PIN_FLDT_BINSTR     = 12  
	PIN_FLDT_ERR        = 13
	PIN_FLDT_DECIMAL    = 14
	PIN_FLDT_TIME       = 15
	PIN_FLDT_TEXTBUF    = 16
	PIN_FLDT_ERRBUF     = PIN_FLDT_ERR
end

# 
def define_constants
	fields = com.portal.pcm.Field
	fields.constants.each do |c| 
		puts "#{c} #{com.portal.pcm.Field.const_get(c)}"
	end
end


class Hash
	def pin_dump(level=0)
		buf = []
		max = self.keys.inject(0){|max,o| s = o.size; max = max > s ? max : s }
		max = max > 30 ? max : 30
		format = "%d %-#{max}s %s\n"
		for k, v in self
			if v.is_a?(Hash)
				buf << v.pin_dump(level+1)
			else
				buf << format %[level, k, v]
			end
		end
		buf
	end
end

class Java::ComPortalPcm::PortalContext

	# poid_str: A string version of a poid
	def robj(poid_str)
		ary = poid_str.split
		poid_db, poid_type, poid_id, poid_rev = "0.0.0.1", nil, nil, nil
		case ary.size 
			when 4 then poid_db, poid_type, poid_id, poid_rev = ary
			when 3 then poid_db, poid_type, poid_id = ary
			when 2 then poid_type, poid_id = ary
		end
		
		flist = xop("READ_OBJ", 0, {"PIN_FLD_POID"=>"#{poid_db} #{poid_type} #{poid_id}"})
	end

	# Execute an opcode
	# opcode: The int or string of the opcode. For example "ACT_FIND_VERIFY"
	# flags: An int for flags
	# flist: A +Hash+, +String+, or +FList+
	# NOTE: Returns the same type as supplied.
	def xop(opcode, flags, flist)
		if String === opcode
			opcode = Java::ComPortalPcm::PortalOp.const_get(opcode.upcase)
		end

		in_flist = case flist
			when Hash
				FList.from_hash(flist)
			when String
				FList.create_from_string(flist)
			else
				flist
			end

		ret_flist = self.opcode(opcode, flags, in_flist)

		return case flist
			when Hash
				ret_flist.to_hash
			when String
				ret_flist.to_s
			else
				ret_flist
			end

	end
end

class Java::ComPortalPcm::Poid
	class << self
		# Convert db, type, id, rev into a poid.
		def from_string(str)
			ary = str.split
			if ary.size == 2
				(db, poid_id0, type) = [1,ary[1],ary[0]]
			else
				(db, poid_id0, type) = [ary[0],ary[2],ary[1]]
			end
			if (db =~ /\./)
				ary = db.split(".")
				db = (ary[3].to_i) + (256*ary[2].to_i) + (256*256*ary[1].to_i) + (256*256*256*ary[0].to_i)
			end
			self.new(db.to_i, poid_id0.to_i, type)
		end
	end
end

class Java::ComPortalPcm::FList

  def [](field)
		fld = FList.field(field)
		get(fld)
  end

  def []=(key,value)
		xset(key, value)
  end

  def xset(field,value)
		fld = self.class.field(field)
  	case fld.get_pin_type
  	when /DECIMAL/
					flist.set(field,java.math.BigDecimal.new(value))
		when /TSTAMP/
			value = java.util.Date.new(value.to_i * 1000)
		when /INT|ENUM/
			value = value.to_i
		when /PIN_FLDT_POID/
			value = Poid.from_string(value)
		end
		set(fld, value)
		self
  end
  
  def dump
  	buf = []
  	hash = self.to_hash  	
  end

	# to_str is the normal way of seeing things. +as_string+ is ackward.
	def to_str
		self.as_string
	end
	def to_s
		self.as_string
	end
	
	def to_hash
		hash = {}
		get_fields.each do |fld|
			val = self.get(fld)
			key = fld.name_string
			
  		case fld.type_id
			when PIN_FLDT_ARRAY
				pairs = val.pairs
				while (pairs.hasMoreElements)
					pair = pairs.nextPair
					idx = pair.key
					hash[key] ||= {}
					hash[key][idx] = pair.value.to_hash
				end
			when PIN_FLDT_POID
				hash[key] = val.to_s
			when PIN_FLDT_TSTAMP
				hash[key] = (val.getTime() / 1000)
			when PIN_FLDT_DECIMAL
				#hash[key] = val.nil? ? "" : java.math.BigDecimal.new(val.to_string)
				hash[key] = val.nil? ? "" : val.to_string
			when PIN_FLDT_BUF
				buf = val.to_s
				buf = FList.create_from_string(buf).to_str rescue buf
				hash[key] = buf
  		else
  			hash[key] = val
  		end
		end
		hash
	end

	class <<	self

		# Create from a doc/string
		def from_str(doc)
			create_from_string(doc)
		end
	
		# Converts Camel case BigDeal to BIG_DEAL
		def to_pinname(str)
			return str if str =~ /_FLD_/
			name = str.to_s.
				gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
				gsub(/([a-z\d])([A-Z])/,'\1_\2').
				upcase
			"PIN_FLD_#{name}"
		end
	
		# Uses the com.portal.pcm.Field class to instatiate
		# the singleton for given +field+
		# where +field+ is a string or symbol
		def field(field)
			fld = com.portal.pcm.Field.from_pin_name(field)
			fld ||= com.portal.pcm.Field.from_name(field)
			fld ||= com.portal.pcm.Field.from_name("Fld" + field)
			return fld if fld

			pin_name = to_pinname(field)
			fld = Java::ComPortalPcm::Field
			fld = fld.from_pin_name(pin_name)
			return fld if fld
			
			if name = sdk_field(field)
				com.portal.pcm.Field.from_pin_name(name)
			end
			
			rescue
				raise "Cannot load field named #{field}"
		end
		
		def sdk_field(field)
			field = field.to_s if Symbol === field
			ary = @@dd_fields.keys.grep /#{field}/i
			if ary.size == 1
				ary.first
			end
		end


		# Create a new FList from the supplied Ruby hash.
		# PIN_FLDT_TSTAMP | Time | Date | Ruby is seconds. Java is ms.
		def from_hash(hash)
			
			flist = com.portal.pcm.FList.new
			hash.each do |k,v|
				if !field = self.field(k)
					raise "Bad load of #{k} => #{v}"
				end
    		
    		case field.type_id
    		when PIN_FLDT_POID
					flist.set(field,Poid.from_string(v))
				when PIN_FLDT_STR,
						 PIN_FLDT_INT,
				     PIN_FLDT_ENUM
					flist.set(field,v)
				when PIN_FLDT_TSTAMP
					d = java.util.Date.new(v.to_i * 1000)
					flist.set(field,d)
				when PIN_FLDT_DECIMAL
					v = "0" if v.is_a?(String) and v.size == 0
					flist.set(field,java.math.BigDecimal.new(v))
				when PIN_FLDT_ARRAY
					# Two ways. Use SA and set OR setElement
					# sa = SparseArray.new
					for key, value in v
						# Element.const_get "ELEMID_ANY" => -1
						idx = key == "*" ? -1: key
						#sa.add(idx, self.from_hash(value))
						flist.setElement(field, idx, value ? self.from_hash(value) : nil)
					end					
					#flist.set(field,sa)
				when PIN_FLDT_SUBSTRUCT
    			key = v.keys.first
    			value = self.from_hash(v[key])
					flist.set(field,value)
				when PIN_FLDT_BUF
					bbuf = Java::com.portal.pcm.ByteBuffer.new
					#bbuf.set_bytes(v.sub(/\n\u0000.*?$/,"").to_java_bytes)
					bbuf.set_bytes(v.to_java_bytes)
					flist.set(field, bbuf)
				else
    			raise "Unknown #{field} #{field.pintype} #{field.type_id} #{v.inspect}"
    		end
			end
			flist
		end
		
		def from_str(str)
			create_from_string(str)
		end

		# Loads fields from the database.
		def sdk_fields(ctx)
			@@dd_fields
			rescue
				flist = Java::ComPortalPcm::FList.new
				#poid = Java::ComPortalPcm::Poid.from_string "1 /dd/objects 0"
				# poid = com.portal.pcm.Poid.value_of()
				poid = Java::ComPortalPcm::Poid.value_of("$DB /dd/objects 0",1)
				flist.set(Java::ComPortalPcmFields::FldPoid.getInst,poid)
				out_flist = ctx.opcode(PCM_OP_SDK_GET_FLD_SPECS, flist)
				hash = out_flist.to_hash
				
				#hash = { "PIN_FLD_POID" => "0.0.0.1 /dd/objects 0 0" }
				#flist = Java::ComPortalPcm::FList.from_hash(hash)
				#hash = Java::ComPortalPcm::FList.to_hash(out_flist)

				Struct.send(:remove_const, :PinFld) if Struct.const_defined?("PinFld")
				pf = Struct.new("PinFld", :name, :num, :type, :status)
				dd_fields = {}
				hash["PIN_FLD_FIELD"].each do |i,href|
					dd_fields[href["PIN_FLD_FIELD_NAME"]] = pf.new(href["PIN_FLD_FIELD_NAME"], href["PIN_FLD_FIELD_NUM"].to_i, href["PIN_FLD_FIELD_TYPE"].to_i, href["PIN_FLD_STATUS"].to_i)	
				end
			  @@dd_fields = dd_fields
		end

	end
	
end




if false # __FILE__ == $0
	flist = com.portal.pcm.FList.new
	poid = com.portal.pcm.Poid.value_of("$DB /service/pcm_client 1", 1)
	flist.set(com.portal.pcm.fields.FldPoid.getInst,poid)
	flist.set(com.portal.pcm.Field.from_name("FldName"),"Yummy")
	flist.set(FList.field("Name"),"Yummy")	
	fld = com.portal.pcm.Field.from_name("FldName")
	
	hash = {
			"PIN_FLD_POID"         => "0.0.0.1 /service/pcm_client -1 0", 
			"PIN_FLD_LOGIN"        => "root.0.0.0.1", 
			"PIN_FLD_PASSWD_CLEAR" => "password", 
			"PIN_FLD_CM_PTRS"=>{0=>{"PIN_FLD_CM_PTR"=>"ip localhost 11960"}}, 
			"PIN_FLD_TYPE"=>1
		}
	flist = FList.from_hash(hash)
	ctx = com.portal.pcm.PortalContext.new(flist)

end

