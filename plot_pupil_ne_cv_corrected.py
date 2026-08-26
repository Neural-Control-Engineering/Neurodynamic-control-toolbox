"""Extended Data Figure 6-1: pupil vs pupil+NE as state-transition drivers,
under the CORRECTED column-routed GLM-HMM.

Supersedes plot_pupil_ne_cv.py, which plotted the April fit. In that version a
single input matrix fed BOTH sub-models, so the "pupil-only" arm carried
baseline pupil in the observation GLM (the circularity the reviewer raised) and
NE entered the choice model as well as the transitions. Here both arms share an
identical choice GLM (stimulus + bias) and differ only in what drives the
transitions, which is the comparison the Results paragraph claims.

Reads:  glmhmm_pupil_ne_cv_corrected.csv
Writes: glmhmm_pupil_ne_cv_corrected_figure.svg / .png
"""
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(_HERE, 'glmhmm_pupil_ne_cv_corrected.csv')
OUT = os.path.join(_HERE, 'glmhmm_pupil_ne_cv_corrected_figure')

df = pd.read_csv(CSV)

mpl.rcParams.update({
    'font.family': ['Helvetica Neue', 'Helvetica', 'Arial', 'DejaVu Sans'],
    'font.size': 10,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'axes.linewidth': 0.8,
    'axes.edgecolor': '#333333',
    'axes.labelcolor': '#222222',
    'xtick.color': '#333333',
    'ytick.color': '#333333',
    'xtick.major.size': 3,
    'ytick.major.size': 3,
    'xtick.major.width': 0.8,
    'ytick.major.width': 0.8,
    'axes.grid': True,
    'grid.color': '#E8E8E8',
    'grid.linewidth': 0.6,
    'grid.alpha': 1.0,
    'axes.axisbelow': True,
})

PUPIL_COLOR = '#8B7355'     # muted brown
PUPIL_NE_COLOR = '#4F6D8A'  # muted slate blue
BG = '#FAFAFA'

ARMS = [('pupil', 'Pupil', PUPIL_COLOR, -0.08),
        ('pupil_ne', 'Pupil + NE', PUPIL_NE_COLOR, +0.08)]

metrics = [('accuracy', 'Accuracy'),
           ('roc_auc', 'ROC-AUC'),
           ('pr_auc', 'PR-AUC'),
           ('bits_per_trial', 'Bits / trial')]

fig, axes = plt.subplots(2, 2, figsize=(8, 6), facecolor=BG)
fig.subplots_adjust(left=0.1, right=0.97, top=0.90, bottom=0.1,
                    hspace=0.42, wspace=0.3)

print(f"{'metric':16}{'K':>3}{'pupil':>10}{'pupil+NE':>11}{'diff':>9}{'paired p':>10}")
for ax, (metric, label) in zip(axes.flat, metrics):
    ax.set_facecolor(BG)
    for key, disp, color, offset in ARMS:
        sub = df[df['model'] == key]
        Ks = sorted(sub['K'].unique())
        means = [sub[sub['K'] == k][metric].mean() for k in Ks]
        sems = [sub[sub['K'] == k][metric].sem() for k in Ks]
        for k in Ks:
            vals = sub[sub['K'] == k][metric].values
            rng = np.random.default_rng(abs(hash((key, k, metric))) & 0xFFFF)
            jitter = (rng.random(len(vals)) - 0.5) * 0.06
            ax.scatter(np.full_like(vals, k, dtype=float) + offset + jitter, vals,
                       s=14, color=color, alpha=0.35, edgecolors='none', zorder=2)
        ax.errorbar(np.array(Ks) + offset, means, yerr=sems, fmt='o-', color=color,
                    markersize=6, linewidth=1.5, capsize=0, zorder=3,
                    label=disp, markeredgecolor='white', markeredgewidth=0.8)
    ax.set_xlabel('Number of states (K)')
    ax.set_ylabel(label)
    ax.set_xticks(sorted(df['K'].unique()))
    ax.set_xlim(min(df['K']) - 0.4, max(df['K']) + 0.4)

    # paired comparison per K, printed for the legend/text
    for k in sorted(df['K'].unique()):
        a = df[(df.model == 'pupil') & (df.K == k)].sort_values('fold')[metric].values
        b = df[(df.model == 'pupil_ne') & (df.K == k)].sort_values('fold')[metric].values
        _, p = stats.wilcoxon(a, b)
        print(f'{metric:16}{k:>3}{a.mean():>10.4f}{b.mean():>11.4f}'
              f'{(b - a).mean():>+9.4f}{p:>10.3f}')

axes[0, 0].legend(frameon=False, loc='lower right', fontsize=9)
fig.suptitle('Adding cortical NE to the state-transition model does not improve fit',
             fontsize=11, color='#222222', y=0.975)

for ext in ('svg', 'png'):
    plt.savefig(f'{OUT}.{ext}', dpi=300, facecolor=BG, bbox_inches='tight')
print(f'\nSaved: {OUT}.svg / .png')
