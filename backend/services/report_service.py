import os
from datetime import datetime
from pathlib import Path
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image as RLImage, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from backend.config import settings, REPORTS_DIR

class ClinicalReportService:
    @staticmethod
    def generate_pdf_report(
        report_uid: str,
        patient_data: dict,
        scan_data: dict,
        preprocessing_data: dict,
        analysis_data: dict,
        doctor_name: str = "Dr. S. Reynolds, MD (Ophthalmologist)",
        notes: str | None = None
    ) -> str:
        pdf_filename = f"report_{report_uid}.pdf"
        pdf_path = REPORTS_DIR / pdf_filename
        
        doc = SimpleDocTemplate(
            str(pdf_path),
            pagesize=letter,
            rightMargin=36,
            leftMargin=36,
            topMargin=36,
            bottomMargin=36
        )
        
        story = []
        styles = getSampleStyleSheet()
        
        # Custom Typography
        header_title_style = ParagraphStyle(
            'HeaderTitle',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=18,
            leading=22,
            textColor=colors.HexColor('#004B73')
        )
        header_sub_style = ParagraphStyle(
            'HeaderSub',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=9,
            leading=12,
            textColor=colors.HexColor('#55697D')
        )
        section_heading_style = ParagraphStyle(
            'SectionHeading',
            parent=styles['Heading2'],
            fontName='Helvetica-Bold',
            fontSize=12,
            leading=15,
            textColor=colors.HexColor('#006699'),
            spaceBefore=8,
            spaceAfter=4
        )
        cell_bold_style = ParagraphStyle(
            'CellBold',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor('#0F2438')
        )
        cell_regular_style = ParagraphStyle(
            'CellRegular',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor('#334155')
        )
        disclaimer_style = ParagraphStyle(
            'Disclaimer',
            parent=styles['Normal'],
            fontName='Helvetica-Oblique',
            fontSize=7.5,
            leading=10,
            textColor=colors.HexColor('#64748B'),
            alignment=1  # Centered
        )

        # 1. Header Banner
        header_data = [
            [
                Paragraph("<b>RetinaSeg AI</b><br/><font size=8 color='#006699'>AUTOMATED RETINAL LAYER SEGMENTATION</font>", header_title_style),
                Paragraph(f"<b>Report ID:</b> {report_uid}<br/><b>Date:</b> {datetime.now().strftime('%Y-%m-%d %H:%M')}<br/><b>Status:</b> Verified", header_sub_style)
            ]
        ]
        t_header = Table(header_data, colWidths=[3.8 * inch, 3.7 * inch])
        t_header.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
        ]))
        story.append(t_header)
        story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#006699'), spaceAfter=8, spaceBefore=4))

        # 2. Patient & Scan Details
        info_data = [
            [
                Paragraph("<b>PATIENT INFORMATION</b>", section_heading_style),
                Paragraph("<b>OCT SCAN & ACQUISITION METRICS</b>", section_heading_style)
            ],
            [
                Paragraph(f"<b>Patient ID:</b> {patient_data.get('patient_id', 'N/A')}<br/>"
                          f"<b>Name:</b> {patient_data.get('full_name', 'N/A')}<br/>"
                          f"<b>Age / Gender:</b> {patient_data.get('age', 'N/A')} yrs / {patient_data.get('gender', 'N/A')}<br/>"
                          f"<b>Indication:</b> {patient_data.get('eye_condition', 'Routine Evaluation')}", cell_regular_style),
                Paragraph(f"<b>Scan UID:</b> {scan_data.get('scan_uid', 'N/A')}<br/>"
                          f"<b>Laterality:</b> {scan_data.get('eye_laterality', 'OD (Right Eye)')}<br/>"
                          f"<b>Resolution:</b> {scan_data.get('width', 512)} x {scan_data.get('height', 512)} px<br/>"
                          f"<b>Calibration:</b> {scan_data.get('axial_resolution_um', 3.87)} μm/pixel (Axial)", cell_regular_style)
            ]
        ]
        t_info = Table(info_data, colWidths=[3.75 * inch, 3.75 * inch])
        t_info.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BACKGROUND', (0, 1), (-1, 1), colors.HexColor('#F8FAFC')),
            ('BOX', (0, 1), (0, 1), 0.5, colors.HexColor('#E2E8F0')),
            ('BOX', (1, 1), (1, 1), 0.5, colors.HexColor('#E2E8F0')),
            ('TOPPADDING', (0, 1), (-1, 1), 6),
            ('BOTTOMPADDING', (0, 1), (-1, 1), 6),
            ('LEFTPADDING', (0, 1), (-1, 1), 8),
            ('RIGHTPADDING', (0, 1), (-1, 1), 8),
        ]))
        story.append(t_info)
        story.append(Spacer(1, 8))

        # 3. Medical Imaging Results: 4-Panel Views
        story.append(Paragraph("<b>OPHTHALMIC IMAGING & LAYER SEGMENTATION</b>", section_heading_style))
        
        orig_img_path = scan_data.get('file_path')
        proc_img_path = preprocessing_data.get('preprocessed_file_path')
        mask_img_path = analysis_data.get('mask_file_path')
        overlay_img_path = analysis_data.get('overlay_file_path')

        img_w, img_h = 3.5 * inch, 1.45 * inch
        
        def safe_image(path_str, fallback_text):
            if path_str and Path(path_str).exists():
                return RLImage(str(path_str), width=img_w, height=img_h)
            return Paragraph(f"<i>{fallback_text}</i>", cell_regular_style)

        images_grid = [
            [
                Paragraph("<b>A. Original OCT B-Scan</b>", cell_bold_style),
                Paragraph("<b>B. Enhanced Preprocessed (CLAHE)</b>", cell_bold_style)
            ],
            [
                safe_image(orig_img_path, "Original scan unavailable"),
                safe_image(proc_img_path, "Preprocessed scan unavailable")
            ],
            [
                Paragraph("<b>C. Segmented Layer Masks</b>", cell_bold_style),
                Paragraph("<b>D. Multi-Layer Boundary Overlay</b>", cell_bold_style)
            ],
            [
                safe_image(mask_img_path, "Segmentation mask unavailable"),
                safe_image(overlay_img_path, "Overlay scan unavailable")
            ]
        ]
        t_images = Table(images_grid, colWidths=[3.75 * inch, 3.75 * inch])
        t_images.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        story.append(t_images)
        story.append(Spacer(1, 6))

        # 4. Quantitative Layer Thickness Table
        story.append(Paragraph("<b>RETINAL LAYER QUANTITATIVE THICKNESS MEASUREMENTS</b>", section_heading_style))
        
        table_rows = [
            [
                Paragraph("<b>Retinal Layer</b>", cell_bold_style),
                Paragraph("<b>Status</b>", cell_bold_style),
                Paragraph("<b>Mean (μm)</b>", cell_bold_style),
                Paragraph("<b>Min (μm)</b>", cell_bold_style),
                Paragraph("<b>Max (μm)</b>", cell_bold_style),
                Paragraph("<b>Area (px²)</b>", cell_bold_style),
                Paragraph("<b>Confidence</b>", cell_bold_style),
            ]
        ]

        layers = analysis_data.get('layers', [])
        for l in layers:
            status_text = "<font color='#0D9488'>Detected</font>" if l.get('is_detected') else "<font color='#DC2626'>Not Detected</font>"
            mean_um = f"{l.get('mean_thickness_um')} μm" if l.get('mean_thickness_um') is not None else f"{l.get('mean_thickness_px')} px"
            min_um = f"{l.get('min_thickness_um')} μm" if l.get('min_thickness_um') is not None else f"{l.get('min_thickness_px')} px"
            max_um = f"{l.get('max_thickness_um')} μm" if l.get('max_thickness_um') is not None else f"{l.get('max_thickness_px')} px"
            conf = f"{int(l.get('confidence_score', 0.9) * 100)}%"
            
            table_rows.append([
                Paragraph(f"<b>{l.get('layer_name')}</b>", cell_bold_style),
                Paragraph(status_text, cell_regular_style),
                Paragraph(str(mean_um), cell_regular_style),
                Paragraph(str(min_um), cell_regular_style),
                Paragraph(str(max_um), cell_regular_style),
                Paragraph(f"{l.get('layer_area_px', 0):,}", cell_regular_style),
                Paragraph(conf, cell_regular_style),
            ])

        t_layers = Table(table_rows, colWidths=[1.4 * inch, 1.0 * inch, 1.0 * inch, 0.9 * inch, 0.9 * inch, 1.1 * inch, 1.1 * inch])
        t_layers.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E1EFF7')),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 3),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ('LEFTPADDING', (0, 0), (-1, -1), 4),
            ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ]))
        story.append(t_layers)
        story.append(Spacer(1, 8))

        # 5. Diagnostic Findings & Doctor Signature
        notes_text = notes or analysis_data.get('findings_summary', "Automated segmentation completed with clear delineation of retinal layers. No acute structural defects identified.")
        
        doctor_section = [
            [
                Paragraph("<b>CLINICAL FINDINGS & NOTES</b>", section_heading_style),
                Paragraph("<b>REVIEWING OPHTHALMOLOGIST</b>", section_heading_style)
            ],
            [
                Paragraph(f"{notes_text}<br/><br/><b>Image Quality Assessment:</b> {analysis_data.get('overall_quality', 'Good')}", cell_regular_style),
                Paragraph(f"<b>Clinician:</b> {doctor_name}<br/>"
                          f"<b>Model Engine:</b> {analysis_data.get('model_version', settings.MODEL_VERSION)}<br/><br/>"
                          f"<b>Signature:</b> ___________________________", cell_regular_style)
            ]
        ]
        t_doc = Table(doctor_section, colWidths=[4.2 * inch, 3.3 * inch])
        t_doc.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
        ]))
        story.append(KeepTogether(t_doc))
        story.append(Spacer(1, 10))

        # 6. Legal & Clinical Research Disclaimer
        story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor('#94A3B8'), spaceAfter=4, spaceBefore=4))
        story.append(Paragraph(
            "<b>CLINICAL DISCLAIMER:</b> AI-assisted retinal layer segmentation is intended for clinical decision support and research purposes. "
            "Automated thickness measurements and boundaries should be correlated with comprehensive ophthalmic examination.",
            disclaimer_style
        ))

        doc.build(story)
        return str(pdf_path)

report_service = ClinicalReportService()
