#!/bin/bash

module load fsl
DATAPATH=/path/to/data

# Get list of subjects
ls -d /path/to/data/*/ | awk -F/ '{ print $9}' >> SESlist.txt

# Get list of sessions from subjects
for ses in `cat SESlist.txt`; do for subj in `ls /path/to/data/${ses}/ | awk -Fsub- '{ print $2}'`;do echo ${subj},${ses};done;done >> subjseslist.txt

#Get subject and session
for line in `cat subjseslist.txt`; do SUBJ=`echo $line | cut -d, -f1`; MONTH=`echo $line | cut -d, -f2`; 

#Create a mask of the L and R gray and white matter from the aseg
fslmaths ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_desc-aseg_dseg.nii.gz -thr 42 -uthr 42 gray_R;
fslmaths ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_desc-aseg_dseg.nii.gz -thr 41 -uthr 41 white_R;
fslmaths ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_desc-aseg_dseg.nii.gz -thr 2 -uthr 2 white_L;
fslmaths ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_desc-aseg_dseg.nii.gz -thr 3 -uthr 3 gray_L;

#Merge L/R
fslmaths white_L.nii.gz -add white_R.nii.gz white.nii.gz;
fslmaths gray_L.nii.gz -add gray_R.nii.gz gray.nii.gz;

#Binarize mask
fslmaths white.nii.gz -bin white_mask.nii.gz; 
fslmaths gray.nii.gz -bin gray_mask.nii.gz; 

#Use each mask to pull intensities from the T1/T2 from just the mask
fslmeants -i ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_mod-defaced_T1w.nii.gz -m white_mask.nii.gz --showall | head -4 | tail -1 > whitehist_T1.txt;
fslmeants -i ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_mod-defaced_T1w.nii.gz -m gray_mask.nii.gz --showall | head -4 | tail -1 > grayhist_T1.txt;
fslmeants -i ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_mod-defaced_T2w.nii.gz -m white_mask.nii.gz --showall | head -4 | tail -1 > whitehist_T2.txt;
fslmeants -i ${DATAPATH}/${MONTH}/sub-${SUBJ}/sub-${SUBJ}_ses-${MONTH}_space-INFANTMNIacpc_mod-defaced_T2w.nii.gz -m gray_mask.nii.gz --showall | head -4 | tail -1 > grayhist_T2.txt;

#Replace spaces with newlines so can import into R, save into proper folder, with proper name
tr ' ' '\n' < whitehist_T1.txt >> intensity_${MONTH}/whitehist_T1_${SUBJ}_${MONTH}.txt;
tr ' ' '\n' < grayhist_T1.txt >> intensity_${MONTH}/grayhist_T1_${SUBJ}_${MONTH}.txt;
tr ' ' '\n' < whitehist_T2.txt >> intensity_${MONTH}/whitehist_T2_${SUBJ}_${MONTH}.txt;
tr ' ' '\n' < grayhist_T2.txt >> intensity_${MONTH}/grayhist_T2_${SUBJ}_${MONTH}.txt;
done
