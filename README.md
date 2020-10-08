# brm-jruby

## DESCRIPTION:

Wrappers to the Java pcm.jar

## FEATURES

* Convert hash to an FList

## SYNOPSIS
        CLASSPATH=$PIN_HOME/jars irb -I lib -r brm-jruby

        hash = {
                        "PIN_FLD_POID"         => "0.0.0.1 /service/pcm_client -1 0",
                        "PIN_FLD_LOGIN"        => "root.0.0.0.1",
                        "PIN_FLD_PASSWD_CLEAR" => "password",
                        "PIN_FLD_CM_PTRS"=>{0=>{"PIN_FLD_CM_PTR"=>"ip localhost 11960"}},
                        "PIN_FLD_TYPE"=>1
                }
        flist = FList.from_hash(hash)

# REQUIREMENTS

The following need to be on your classpath or JRuby's -I.

* pcm.jar
* pcmext.jar

## INSTALL:

* sudo gem install brm-jruby

## DEVELOPERS:

After checking out the source, run:

  $ rake wtf

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

## LICENSE

All rights reserved by author.
