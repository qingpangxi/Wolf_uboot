#!/bin/sh
#./build_uboot.sh ---> build the uboot images for tc4
#./build_uboot.sh tc4_plus -->build the uboot images for tc4_plus
#./build_uboot.sh clean ----> clean the images
#./build_uboot.sh windows ----> encrypt the uboot image in window pc



option1="tc4_plus"
sec_path="../CodeSign4SecureBoot/"
CPU_JOB_NUM=$(grep processor /proc/cpuinfo | awk '{field=$NF};END{print field+1}')
ROOT_DIR=$(pwd)
CUR_DIR=${ROOT_DIR##*/}


case "$1" in
	clean)
		echo make clean
		rm u-boot.bin
		rm u-boot-exynos4412-evt0-nonfused.bin
		rm u-boot-exynos4212-evt0-nonfused.bin
		rm u-boot-exynos4412-evt1-efused.bin
		make mrproper
		;;
	windows)
		make tc4_android_config
		make -j$CPU_JOB_NUM
		echo "******************************************************************************************"
		echo "[NOTICE]please copy "checksum_bl2_14k.bin" and "u-boot.bin" to your"
		echo " windows pc for encryption and gernerate the final bin file for your using "
		echo "******************************************************************************************"
		;;
		
	*)
			
		if [ ! -d $sec_path ]
		then
			echo "**********************************************"
			echo "[ERR]please get the CodeSign4SecureBoot first"
			echo "**********************************************"
			return
		fi
		
		if [ -z $1 ]
		then
			make tc4_android_config
		elif [ $1 = $option1 ]
		then
			make tc4_plus_android_config
		else
			echo please input right parameter.
			exit 0
		fi
		
		make -j$CPU_JOB_NUM
		
		if [ ! -f checksum_bl2_14k.bin ]
		then
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "There are some error(s) while building uboot, please use command make to check."
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			exit 0
		fi
		
		cp -rf checksum_bl2_14k.bin $sec_path
		cp -rf u-boot.bin $sec_path
		rm checksum_bl2_14k.bin
		
		cd $sec_path
		./codesigner_v21 -v2.1 checksum_bl2_14k.bin BL2.bin.signed.4412 Exynos4412_V21.prv -STAGE2
		./codesigner_v21 -v2.1 checksum_bl2_14k.bin BL2.bin.signed.4212 Exynos4212_V21.prv -STAGE2
		
		
		cat E4412.S.BL1.SSCR.EVT1.1.bin BL2.bin.signed.4412 paddingaa u-boot.bin > u-boot-exynos4412-evt1-efused.bin
		cat E4212.S.BL1.SSCR.EVT1.1.bin BL2.bin.signed.4212 paddingaa u-boot.bin > u-boot-exynos4212-evt1-efused.bin
		
		# gernerate the uboot bin file support trust zone
		cat E4412.S.BL1.SSCR.EVT1.1.bin E4412.BL2.TZ.SSCR.EVT1.1.bin all00_padding.bin u-boot.bin E4412.TZ.SSCR.EVT1.1.bin > u-boot-exynos4412-evt1-efused-tz.bin
		cat E4212.BL1.TZ.SSCR.EVT1.1.bin E4212.BL2.TZ.SSCR.EVT1.1.bin u-boot.bin E4212.TZ.SSCR.EVT1.1.bin > u-boot-exynos4212-evt1-efused-tz.bin
		
		
		mv u-boot-exynos4212-evt1-efused.bin $ROOT_DIR
		mv u-boot-exynos4412-evt1-efused.bin $ROOT_DIR
		mv u-boot-exynos4412-evt1-efused-tz.bin $ROOT_DIR
		mv u-boot-exynos4212-evt1-efused-tz.bin $ROOT_DIR
		
		rm checksum_bl2_14k.bin
		rm BL2.bin.signed.4412
		rm BL2.bin.signed.4212
		rm u-boot.bin

		echo u-boot-exynos4412-evt1-efused.bin generated for Quad core secure boot,use this one to fuse exyons 4412 evt1.
		echo echo Please use sd_fusing.sh in sdfuse_q directory with su permission for programming the u-boot to SD card. Ex: ./sd_fusing.sh /dev/sdb
		echo 
		echo 
		;;
		
esac
